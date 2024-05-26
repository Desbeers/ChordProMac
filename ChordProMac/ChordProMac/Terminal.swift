//
//  Terminal.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// Terminal utilities
public enum Terminal {
    // Just a placeholder
}

public extension Terminal {

    /// Run a script in the shell and return its output
    /// - Parameter arguments: The arguments to pass to the shell
    /// - Returns: The output from the shell
    static func runInShell(arguments: [String]) async -> Output {
        /// The normal output
        var allOutput: [String] = []
        /// The error output
        var allErrors: [String] = []
        /// Await the results
        for await streamedOutput in runInShell(arguments: arguments) {
            switch streamedOutput {
            case let .standardOutput(output):
                allOutput.append(output)
            case let .standardError(error):
                allErrors.append(error)
            }
        }
        /// Return the output
        return Output(
            standardOutput: allOutput.joined(),
            standardError: allErrors.joined()
        )
    }

    /// Run a script in the shell and return its output
    /// - Parameter arguments: The arguments to pass to the shell
    /// - Returns: The output from the shell as a stream
    static func runInShell(arguments: [String]) -> AsyncStream<StreamedOutput> {

        /// Create the task
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["--login", "-c"] + arguments
        /// Standard output
        let pipe = Pipe()
        task.standardOutput = pipe
        /// Error output
        let errorPipe = Pipe()
        task.standardError = errorPipe
        /// Try to run the task
        do {
            try task.run()
        } catch {
            print(error.localizedDescription)
        }
        /// Return the stream
        return AsyncStream { continuation in
            pipe.fileHandleForReading.readabilityHandler = { handler in
                guard let standardOutput = String(data: handler.availableData, encoding: .utf8) else {
                    return
                }
                guard !standardOutput.isEmpty else {
                    return
                }
                continuation.yield(.standardOutput(standardOutput))
            }
            errorPipe.fileHandleForReading.readabilityHandler = { handler in
                guard let errorOutput = String(data: handler.availableData, encoding: .utf8) else {
                    return
                }
                guard !errorOutput.isEmpty else {
                    return
                }
                continuation.yield(.standardError(errorOutput))
            }
            /// Finish the stream
            task.terminationHandler = { _ in
                continuation.finish()
            }
        }
    }
}

extension Terminal {

    /// The complete output from the shell
    public struct Output {
        /// The standard output
        public var standardOutput: String
        /// The standard error
        public var standardError: String
    }

    /// The stream output from the shell
    public enum StreamedOutput {
        /// The standard output
        case standardOutput(String)
        /// The standard error
        case standardError(String)
    }
}

extension Terminal {

    static func exportDocument(document: ChordProDocument) async throws -> (data: Data?, exportURL: URL) {

        /// For now, just use the official **ChordPro** application to create the PDF
        /// - Note: The executable should be packed in this application
        let chordProApp = "/Applications/ChordPro.app/Contents/MacOS/chordpro"
        /// Store the export in the temporarily directory
        /// - Note: I don;t read the file URL directly because it might not be saved yet
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        /// Create a source URL
        let sourceURL = temporaryDirectoryURL.appendingPathComponent(document.fileID, conformingTo: .chordProSong)
        /// Create an export URL
        let exportURL = temporaryDirectoryURL.appendingPathComponent(document.fileID, conformingTo: .pdf)
        /// Write the song to the source URL
        do {
            try document.text.write(to: sourceURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            throw ChordProMacError.writeDocumentError
        }
        /// Build the arguments for ChordPro
        let arguments = [
            "\(chordProApp) " +
            "'\(sourceURL.path(percentEncoded: false))' " +
            "--output='" +
            "\(exportURL.path(percentEncoded: false))'"
        ]
        /// Run ChordPro in the shell
        /// - Note: The output is ignored for now
        _ = await Terminal.runInShell(arguments: arguments)
        /// Return the created PDF
        return (try? Data(contentsOf: exportURL), exportURL)
    }
}
