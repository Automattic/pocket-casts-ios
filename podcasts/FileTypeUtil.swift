import Foundation

class FileTypeUtil {
    public class func fileExtension(forType type: String?) -> String {
        guard let type = type else { return ".mp3" }

        if type.contains("video/3gpp") { return ".3gp" }
        else if type.contains("video/3gpp2") { return ".3g2" }
        else if type.contains("video/mp4") { return ".mp4" }
        else if type.contains("video/x-mp4") { return ".mp4" }
        else if type.contains("video/quicktime") { return ".mov" }
        else if type.contains("video/m4v") { return ".m4v" }
        else if type.contains("video/mpeg") { return ".mp4" }
        else if type.contains("video/mpeg2") { return ".mov" }
        else if type.contains("audio/aac") { return ".aac" }
        else if type.contains("audio/3gpp") { return ".3gp" }
        else if type.contains("audio/3gpp2") { return ".3g2" }
        else if type.contains("audio/aiff") { return ".aiff" }
        else if type.contains("audio/x-aiff") { return ".aiff" }
        else if type.contains("audio/amr") { return ".amr" }
        else if type.contains("audio/mp3") { return ".mp3" }
        else if type.contains("audio/mpeg3") { return ".mp3" }
        else if type.contains("audio/x-mp3") { return ".mp3" }
        else if type.contains("audio/x-mpeg3") { return ".mp3" }
        else if type.contains("audio/mp4") { return ".mp4" }
        else if type.contains("audio/x-mp4") { return ".mp4" }
        else if type.contains("audio/mpeg") { return ".mp3" }
        else if type.contains("audio/x-mpeg") { return ".mp3" }
        else if type.contains("audio/wav") { return ".wav" }
        else if type.contains("audio/x-wav") { return ".wav" }
        else if type.contains("audio/x-m4a") { return ".m4a" }
        else if type.contains("audio/x-m4b") { return ".m4b" }
        else if type.contains("audio/x-m4p") { return ".m4p" }

        // fail safe file extensions back to something that most podcasts are
        if type.startsWith(string: "video/") { return ".mov" }

        return ".mp3"
    }

    public class func typeForFileExtension(forExtension fileExtension: String?) -> String {
        guard let fileExtension = fileExtension?.lowercased() else { return "audio/mp3" }

        if fileExtension.contains(".3gp") { return "video/3gpp" }
        else if fileExtension.contains(".3g2") { return "video/3gpp2" }
        else if fileExtension.contains(".mp4") { return "video/mp4" }
        else if fileExtension.contains(".mov") { return "video/quicktime" }
        else if fileExtension.contains(".m4v") { return "video/m4v" }
        else if fileExtension.contains(".aac") { return "audio/aac" }
        else if fileExtension.contains(".aiff") { return "audio/aiff" }
        else if fileExtension.contains(".amr") { return "audio/amr" }
        else if fileExtension.contains(".mp3") { return "audio/mp3" }
        else if fileExtension.contains(".mp4") { return "audio/mp4" }
        else if fileExtension.contains(".wav") { return "audio/wav" }
        else if fileExtension.contains(".m4a") { return "audio/x-m4a" }
        else if fileExtension.contains(".m4b") { return "audio/x-m4b" }
        else if fileExtension.contains(".m4p") { return "audio/x-m4p" }

        return "audio/mp3"
    }

    public class func isSupportedUserFileType(fileName: String?) -> Bool {
        guard let fileName = fileName?.lowercased() else { return false }
        if fileName.contains(".3gp") { return true }
        else if fileName.contains(".3g2") { return true }
        else if fileName.contains(".mp4") { return true }
        else if fileName.contains(".mov") { return true }
        else if fileName.contains(".m4v") { return true }
        else if fileName.contains(".m4a") { return true }
        else if fileName.contains(".aiff") { return true }
        else if fileName.contains(".amr") { return true }
        else if fileName.contains(".mp3") { return true }
        else if fileName.contains(".mp4") { return true }
        else if fileName.contains(".wav") { return true }
        else if fileName.contains(".m4a") { return true }
        else if fileName.contains(".m4b") { return true }
        else if fileName.contains(".m4p") { return true }
        else if fileName.contains(".aac") { return true }
        return false
    }
}
