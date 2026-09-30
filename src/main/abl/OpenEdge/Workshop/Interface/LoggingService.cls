/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : LoggingService
    Purpose     : Expose controlled access to temp log files
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon Jun 01 10:00:00 EDT 2026
    Notes       :

    DOH Mapping: logs.map

    Provides these Endpoints:
    - /config: returns the ABL application's primary logging.config path and JSON contents
    - /verbosity/{type}: sets the logging level for a specific logger in the logging.config
    - /list: returns metadata for accessible files in the SESSION:TEMP-DIRECTORY location
    - /download/{id}: returns file content for an indexed file from the /list endpoint
------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

using {&CLASS_PACKAGE}.Common.Util.FileTools.
using OpenEdge.Core.File.
using OpenEdge.Core.Folder.
using OpenEdge.Core.StringConstant.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LogLevelEnum.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.ObjectModelParser.

class {&CLASS_PACKAGE}.Interface.LoggingService
    use-widget-pool
    final
:

    /* Access the service-level logging manager. */
    define protected property oLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.

    /* Return the SESSION:TEMP-DIRECTORY in a consistent manner (without a trailing slash) */
    define public property TempDirectory as Folder no-undo
        get():
            if not valid-object(TempDirectory) then
                TempDirectory = new Folder(right-trim(FileTools:GetFullPathname(session:temp-directory), "/":u), 1).
            return TempDirectory.
        end get.
        private set.

    var private int64 MAX_DOWNLOAD_BYTES = 10 * 1024 * 1024. // Limit to 10MB files for download to prevent abuse.

    define temp-table ttFile no-undo
        field FileID    as character
        field FileName  as character
        field FullPath  as character
        field SizeBytes as int64
        field Modified  as datetime
        index pukPath   as primary unique FullPath
        index ixID      as unique FileID
        .

    method private datetime GetFileTime ( input pcFilePath as character ):
        file-info:file-name = pcFilePath.
        if file-info:full-pathname ne ? then do:
            // Combine the date and time (as milliseconds) to form a proper timestamp.
            return datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).
        end.

        return ?.
    end method. // GetFileTime

    method private void ProcessFolder ( input poFolder as Folder ):
        var Progress.Collections.IIterator<Folder> iter.

        if not poFolder:Exists then
            undo, throw new Progress.Lang.AppError(substitute("Unable to resolve log directory path '&1'":u, poFolder:Name), 0).

        if not poFolder:CanRead then
            undo, throw new Progress.Lang.AppError(substitute("Unable to read log directory path '&1'":u, poFolder:Name), 0).

        oLogger:Debug(substitute("Starting processing of log folder '&1'":u, poFolder:Name)).

        // If folders were found, they will exist in the Folders object and must be processed.
        if valid-object(poFolder:Folders) and poFolder:Folders:Count gt 0 then do:
            assign iter = poFolder:Folders:GetIterator().

            ITERBLOCK:
            do while iter:MoveNext():
                this-object:ProcessFiles(cast(iter:Current, Folder)).
            end.
        end.

        // Process any of the files found in the root of the intended folder.
        if valid-object(poFolder:Files) and poFolder:Files:Count gt 0 then do:
            this-object:ProcessFiles(poFolder).
        end.

        oLogger:Debug(substitute("Completed processing of log folder '&1'":u, poFolder:Name)).
    end method. // ProcessFolder

    method private void ProcessFiles ( input poFolder as Folder ):
        var Progress.Collections.IIterator<File> iter.
        var character cFileExt, cFilePath, cAllowedExtensions = "log":u.

        // Iterate over the list of CURRENT files as provided in the Folder object.
        if valid-object(poFolder:Files) and poFolder:Files:Count gt 0 then
            assign iter = poFolder:Files:GetIterator().

        if not valid-object(iter) then return.

        oLogger:Debug(substitute("Processing Folder: '&1'":u, poFolder:AbsolutePath())).

        ITERBLOCK:
        do while iter:MoveNext():
            // Get the extension and full path from the file object.
            assign
                cFileExt  = cast(iter:Current, File):Extension
                cFilePath = cast(iter:Current, File):AbsolutePath()
                .

            // Skip any files that do not use allowed extensions (only .log files are expected).
            if lookup(cFileExt, cAllowedExtensions) eq 0 then do:
                oLogger:Debug(substitute("Skipping processing of '&1' [not &2]":u, cFilePath, cAllowedExtensions)).
                next ITERBLOCK.
            end.

            if can-find(first ttFile where ttFile.FullPath eq cFilePath) then
                next ITERBLOCK.

            create ttFile.
            assign
                ttFile.FileID    = replace(replace(right-trim(base64-encode(message-digest("SHA-256":u, cFilePath)), "=":u), "+":u, "-":u), "/":u, "_":u)
                ttFile.FileName  = entry(num-entries(cFilePath, "/"), cFilePath, "/")
                ttFile.FullPath  = cFilePath
                ttFile.SizeBytes = cast(iter:Current, File):Size
                ttFile.Modified  = this-object:GetFileTime(cFilePath)
                .
        end.
    end method. // ProcessFiles

    /** ***** Public Endpoints ***** */

    /**
     * Returns the current logging.config utilized by the application.
     */
    method public void GetLoggingConfig ( output pcConfigPath as character,
                                          output poConfigData as JsonObject ):
        var ObjectModelParser oParser = new ObjectModelParser().

        // Search the PROPATH for the config and return a fully qualified path if found.
        assign pcConfigPath = FileTools:GetFullPathname(search("logging.config")).

        if (pcConfigPath gt "":u) eq true then do:
            assign poConfigData = cast(oParser:ParseFile(pcConfigPath), JsonObject) no-error.
            if error-status:error or not valid-object(poConfigData) then
                undo, throw new Progress.Lang.AppError(substitute("Unable to parse logging.config at '&1' as JSON.":u, pcConfigPath), 0).

            oLogger:Debug(substitute("Loaded logging.config from '&1'.":u, pcConfigPath)).
        end.

        finally:
            delete object oParser no-error.
            if not valid-object(poConfigData) then
                assign poConfigData = new JsonObject().
        end finally.
    end method. // GetLoggingConfig

    /**
     * Updates the logging verbosity for a specific configuration item in the logging.config file.
     */
    method public void UpdateLoggingVerbosity ( input pcLoggerName   as character,
                                                input pcLoggingLevel as character ):
        var character cConfigPath, cBackupPath, cConfigName, cLogLevel, cBackupTimestamp.
        var LogLevelEnum oLogLevel.
        var JsonObject oConfig.

        assign
            cConfigName = trim(pcLoggerName)
            cLogLevel   = caps(trim(pcLoggingLevel))
            .

        if (cConfigName gt "":u) ne true then
            undo, throw new Progress.Lang.AppError("Logger config name is required.":u, 0).

        assign oLogLevel = LogLevelEnum:GetEnum(cLogLevel) no-error.
        if error-status:error or
           oLogLevel eq ? or
           oLogLevel eq LogLevelEnum:FATAL or
           oLogLevel eq LogLevelEnum:DEFAULT then
            undo, throw new Progress.Lang.AppError(substitute("Invalid logging level '&1'. Allowed values: OFF, ERROR, WARN, INFO, DEBUG, TRACE.":u,
                                                              cLogLevel),
                                                   0).

        this-object:GetLoggingConfig(output cConfigPath, output oConfig).

        if not oConfig:Has("logger":u) or oConfig:GetType("logger":u) ne JsonDataType:OBJECT then
            undo, throw new Progress.Lang.AppError(substitute("Logger config does not have an expected 'logger' object.":u, cConfigName), 0).

        if not oConfig:GetJsonObject("logger":u):Has(cConfigName) then
            undo, throw new Progress.Lang.AppError(substitute("Logger config name '&1' does not exist in logging config.":u, cConfigName), 0).

        if not oConfig:GetJsonObject("logger":u):GetJsonObject(cConfigName):Has("logLevel":u) then
            undo, throw new Progress.Lang.AppError(substitute("Logger config name '&1' does not have a log level property.":u, cConfigName), 0).

        if not oConfig:GetJsonObject("logger":u):GetJsonObject(cConfigName):Set("logLevel":u, cLogLevel) then
            undo, throw new Progress.Lang.AppError(substitute("Unable to update verbosity for logger config name '&1'.":u, cConfigName), 0).

        assign
            cBackupTimestamp = replace(replace(replace(replace(iso-date(now), "-":u, "":u), ":":u, "":u), "+":u, "":u), ".":u, "":u)
            cBackupPath      = substitute("&1.bak-&2":u, cConfigPath, cBackupTimestamp)
            .

        copy-lob from file cConfigPath to file cBackupPath no-error.
        if error-status:error then
            undo, throw new Progress.Lang.AppError(substitute("Unable to create backup file '&1'.":u, cBackupPath), 0).

        if oConfig:WriteFile(cConfigPath, true) ne true then
            undo, throw new Progress.Lang.AppError(substitute("Unable to write logging.config to '&1'.":u, cConfigPath), 0).

        oLogger:Info(substitute("Updated logging.config key '&1' to '&2'. Backup created at '&3'.":u,
                                cConfigName,
                                cLogLevel,
                                cBackupPath)).
    end method. // UpdateLoggingVerbosity

    /**
     * Returns an array of file objects (1 level deep), representing all .log files in the SESSION:TEMP-DIRECTORY
     */
    method public void GetFileList ( output poFiles as JsonArray ):
        var JsonObject oFile.

        assign poFiles = new JsonArray().

        if not valid-object(this-object:TempDirectory) then
            undo, throw new Progress.Lang.AppError('Unable to resolve SESSION:TEMP-DIRECTORY':u, 0).

        empty temp-table ttFile. // Clear before starting recursive listing.
        this-object:ProcessFolder(this-object:TempDirectory).

        for each ttFile no-lock
              by ttFile.FullPath:
            assign oFile = new JsonObject().
            oFile:Add("id":u, ttFile.FileID).
            oFile:Add("name":u, ttFile.FileName).
            oFile:Add("path":u, ttFile.FullPath).
            oFile:Add("sizeBytes":u, ttFile.SizeBytes).
            oFile:Add("modified":u, ttFile.Modified).
            poFiles:Add(oFile).
        end.
    end method. // GetFileList

    /**
     * Downloads a single .log file from the SESSION:TEMP-DIRECTORY using the file ID provided by GetFileList.
     */
    method public void DownloadFile ( input  pcFileID             as character,
                                      output pcContentDisposition as character,
                                      output poContents           as longchar ):
        assign
            pcContentDisposition = "":u
            poContents           = "":u
            .

        if not valid-object(this-object:TempDirectory) then
            undo, throw new Progress.Lang.AppError('Unable to resolve SESSION:TEMP-DIRECTORY':u, 0).

        empty temp-table ttFile. // Clear before starting recursive listing.
        this-object:ProcessFolder(this-object:TempDirectory).

        if (trim(pcFileID) gt "":u) ne true then
            undo, throw new Progress.Lang.AppError('Invalid File ID.':u, 0).

        find first ttFile no-lock
            where ttFile.FileID eq pcFileID no-error.

        if not available(ttFile) then
            undo, throw new Progress.Lang.AppError('File ID not found.':u, 0).

        assign pcContentDisposition = substitute('attachment; filename="&1"':u, ttFile.FileName).

        if ttFile.SizeBytes gt MAX_DOWNLOAD_BYTES then
            undo, throw new Progress.Lang.AppError(substitute('File exceeds max download size (&1 bytes).':u, string(MAX_DOWNLOAD_BYTES)), 0).

        copy-lob from file ttFile.FullPath to poContents no-error.
        if error-status:error then
            undo, throw new Progress.Lang.AppError('Unable to read file contents.':u, 0).
    end method. // DownloadFile

end class.
