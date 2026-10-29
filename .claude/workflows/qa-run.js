export const meta = {
  name: 'qa-run',
  description: 'Drive QA shards on several simulators in parallel, verify each shard\'s findings as it finishes, then dedupe the run',
  whenToUse: 'Started by the qa skill for runs on more than one simulator. args: {runDir, repo, rules, devices: [{udid, name, account?}], shards: [{id, title, account, settings?, minutes?, destructive?, brief}], accounts?: {plus: ["plus", "plus.2"]}}',
  phases: [
    { title: 'Drive', detail: 'one agent per simulator at a time, working through that simulator\'s shards' },
    { title: 'Verify', detail: 'one agent per finished shard that logged findings' },
    { title: 'Dedupe', detail: 'one agent over the whole run' },
  ],
}

const input = args || {}
if (!input.runDir || !input.repo || !Array.isArray(input.devices) || !input.devices.length || !Array.isArray(input.shards) || !input.shards.length) {
  throw new Error('qa-run needs args {runDir, repo, devices: [{udid, name}], shards: [{id, title, account, brief}]}')
}

const skill = `${input.repo}/.agents/skills/qa`
const scripts = `${skill}/scripts`
const rules = input.rules === 'real' ? 'real' : 'test'
const runName = input.runDir.split('/').filter(Boolean).pop()
const devices = input.devices
const accountOf = shard => shard.account || 'signed-out'
const minutesOf = shard => shard.minutes || 20
const sum = shards => shards.reduce((total, shard) => total + minutesOf(shard), 0)
const shards = input.shards.map(shard => ({ ...shard, account: accountOf(shard) }))

// A profile with several accounts (plus, plus.2, …) spreads its shards over them.
for (const [profile, names] of Object.entries(input.accounts || {})) {
  if (!Array.isArray(names) || names.length < 2) continue
  const perAccount = names.map(() => 0)
  for (const shard of shards.filter(s => s.account === profile).sort((a, b) => minutesOf(b) - minutesOf(a))) {
    const i = perAccount.indexOf(Math.min(...perAccount))
    shard.account = names[i]
    perAccount[i] += minutesOf(shard)
  }
}

// Shards for one account share a simulator, so parallel agents don't change the same Up Next or
// library under each other. Then shards that don't change account data move to idle simulators.
const pinned = shard => shard.destructive && shard.account !== 'signed-out'
const queues = devices.map(() => [])
const load = devices.map(() => 0)
const groups = {}
for (const shard of shards) {
  (groups[shard.account] = groups[shard.account] || []).push(shard)
}
for (const [account, group] of Object.entries(groups).sort((a, b) => sum(b[1]) - sum(a[1]))) {
  const idle = devices.findIndex((device, i) => device.account === account && load[i] === 0)
  const target = idle >= 0 ? idle : load.indexOf(Math.min(...load))
  queues[target].push(...group.sort((a, b) => minutesOf(b) - minutesOf(a)))
  load[target] += sum(group)
}
for (;;) {
  const busiest = load.indexOf(Math.max(...load))
  const idlest = load.indexOf(Math.min(...load))
  const movable = queues[busiest]
    .filter(shard => !pinned(shard))
    .sort((a, b) => minutesOf(a) - minutesOf(b))
    .find(shard => load[idlest] + minutesOf(shard) < load[busiest])
  if (!movable) break
  queues[busiest].splice(queues[busiest].indexOf(movable), 1)
  queues[idlest].push(movable)
  load[busiest] -= minutesOf(movable)
  load[idlest] += minutesOf(movable)
}

const schedule = devices.map((device, i) => ({ device: device.name, udid: device.udid, minutes: load[i], shards: queues[i].map(shard => `${shard.id} [${shard.account}]`) }))
log(schedule.map(s => `${s.device}: ${s.shards.join(', ') || 'idle'} (~${s.minutes} min)`).join('\n'))
if (input.dryRun) {
  return { schedule }
}

function launchCommand(device, shard) {
  const account = accountOf(shard)
  const who = account === 'signed-out' ? '--signed-out' : `--account ${account}`
  return `${scripts}/launch.sh ${device.udid} ${who} --fixture quiet,no-tips`
}

function drivePrompt(shard, device, deviceIndex, shardIndex) {
  const session = `QA ${runName} D${deviceIndex + 1} S${shardIndex + 1}`
  const settings = shard.settings || 'default'
  return `You are a QA tester driving the Pocket Casts iOS app on one iOS simulator. Work through the shard below, find real issues, and log each one as soon as you've confirmed it on screen.

Simulator: ${device.name}, UDID ${device.udid}. Use only this UDID. Other agents are driving other simulators at the same time.
Run folder: ${input.runDir}
Account: ${accountOf(shard)}. Rules: ${rules}. Settings for this shard: ${settings}.
Time budget: about ${minutesOf(shard)} minutes. Run \`date\` when you start and stop starting new scenarios once it's spent.

Read these first: ${skill}/reference/safety.md (the "${rules}" rules apply), ${skill}/reference/driving.md, ${skill}/reference/checks.md and ${skill}/reference/findings.md.

Setup:
1. \`${launchCommand(device, shard)}\` (add scenario fixtures like up-next:5 when a scenario's setup asks for them). It prints [QA] lines and must end with "[QA] ready".
2. Apply the settings "${settings}" as described in checks.md, if not default.
3. DeviceInteractionStartSession with deviceIdentifier "${device.udid}" and sessionIdentifier "${session}" (then "${session} 2", "${session} 3" if the session expires), then one DeviceInteractionSynthesize with activationBundleId au.com.shiftyjelly.podcasts and an empty command.

Shard "${shard.title}" (${shard.id}):

${shard.brief}

Logging: \`python3 ${scripts}/findings.py add ${input.runDir} "<claim>" --severity … --category … --area … --account ${accountOf(shard)} --device "${device.name}" --settings "${settings}" --scenario <scenario id> --step … --actual … --expected … --shot "<your screenshotPath>::<caption>"\`. It regenerates the run's README.md, which the user is watching. Use your own files: \`${scripts}/h.sh "<your session name>"\` for the hierarchy, and the screenshotPath from your own results. The newest files in the shared temp folder can belong to another agent. Don't dig for root causes; a verifier reads the code after you. A one-line --cause is welcome when you already know it.

Before finishing: end your DeviceInteraction session, turn off the settings you turned on (\`${scripts}/sim-settings.sh ${device.udid} reset\`, then \`${scripts}/launch.sh ${device.udid}\`), and put back account state as the rules require.

Return coverage for every scenario in the shard (pass, fail, partial, blocked or skipped, with a short note), the folder names of the findings you logged, any state you changed and couldn't restore, and problems with the tooling that slowed you down.`
}

function verifyPrompt(shard, slugs) {
  return `You verify QA findings for the Pocket Casts iOS app. Read ${skill}/reference/verifying.md and follow it.

Repo: ${input.repo}
Run folder: ${input.runDir}
Findings to verify (folders under findings/): ${slugs.join(', ')}
They came from shard "${shard.title}" (${shard.id}).

Work from the finding files, their screenshots and the code. Don't drive any simulator: other agents are using them. Record every decision with ${scripts}/findings.py (set, section), and return one entry per finding.`
}

function dedupePrompt() {
  return `You do the last pass over a QA run of the Pocket Casts iOS app. Read ${skill}/reference/verifying.md, especially "Duplicates".

Repo: ${input.repo}
Run folder: ${input.runDir}. Earlier runs are in the same parent folder.

1. \`python3 ${scripts}/findings.py list ${input.runDir} --json\`.
2. Merge duplicates within this run (the same root cause seen from different screens or shards): keep the clearest finding, move the others' evidence into it, and reject the rest as "Duplicate of <slug>".
3. Check earlier runs for findings already reported to Linear (\`linear:\` set) with the same root cause, and mark this run's copies as described in verifying.md.
4. \`python3 ${scripts}/findings.py check ${input.runDir}\` and fix what you can.

Return the merges, the matches with earlier runs, and one line on the run's overall state.`
}

const DRIVE = {
  type: 'object',
  properties: {
    coverage: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          scenario: { type: 'string' },
          status: { type: 'string', enum: ['pass', 'fail', 'partial', 'blocked', 'skipped'] },
          notes: { type: 'string' },
        },
        required: ['scenario', 'status'],
      },
    },
    findings: { type: 'array', items: { type: 'string' }, description: 'folder names under findings/ that you created' },
    unrestored: { type: 'array', items: { type: 'string' }, description: 'state changes left in place' },
    toolingProblems: { type: 'string' },
  },
  required: ['coverage', 'findings'],
}

const VERIFY = {
  type: 'object',
  properties: {
    results: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          slug: { type: 'string' },
          status: { type: 'string', enum: ['verified', 'rejected', 'reported', 'candidate'] },
          severity: { type: 'string', enum: ['critical', 'major', 'minor', 'note'] },
          reason: { type: 'string' },
        },
        required: ['slug', 'status', 'reason'],
      },
    },
  },
  required: ['results'],
}

const DEDUPE = {
  type: 'object',
  properties: {
    merged: { type: 'array', items: { type: 'string' }, description: '"<kept slug> ← <rejected slug>"' },
    earlierRuns: { type: 'array', items: { type: 'string' }, description: '"<slug> = <run>/<slug> (<linear>)"' },
    summary: { type: 'string' },
  },
  required: ['summary'],
}

const optional = (model, effort) => ({ ...(model ? { model } : {}), ...(effort ? { effort } : {}) })
const verifications = []

phase('Drive')
const driven = await parallel(devices.map((device, d) => async () => {
  const results = []
  for (let s = 0; s < queues[d].length; s++) {
    const shard = queues[d][s]
    const result = await agent(drivePrompt(shard, device, d, s), {
      label: `drive:${shard.id}`,
      phase: 'Drive',
      schema: DRIVE,
      ...optional(input.driverModel, input.driverEffort),
    })
    results.push({ shard: shard.id, device: device.name, account: accountOf(shard), result })
    const count = result ? result.findings.length : 0
    log(`${device.name}: ${shard.title} ${result ? `done, ${count} finding${count === 1 ? '' : 's'}` : 'failed'}`)
    if (count && input.verify !== false) {
      verifications.push(
        agent(verifyPrompt(shard, result.findings), {
          label: `verify:${shard.id}`,
          phase: 'Verify',
          schema: VERIFY,
          ...optional(input.verifierModel, input.verifierEffort),
        }).catch(() => null),
      )
    }
  }
  return results
}))

const drive = driven.filter(Boolean).flat()
const verify = (await Promise.all(verifications)).filter(Boolean).flatMap(v => v.results)
const total = drive.reduce((n, d) => n + (d.result ? d.result.findings.length : 0), 0)

let dedupe = null
if (total > 1 && input.verify !== false) {
  phase('Dedupe')
  dedupe = await agent(dedupePrompt(), { label: 'dedupe', phase: 'Dedupe', schema: DEDUPE })
}

const failed = drive.filter(d => !d.result).map(d => d.shard)
if (failed.length) log(`No result for: ${failed.join(', ')}`)
return { runDir: input.runDir, schedule, drive, verify, dedupe, failed }
