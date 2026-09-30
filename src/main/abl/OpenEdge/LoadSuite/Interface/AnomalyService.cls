/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : AnomalyService
    Purpose     : Expose special endpoints to force certain behaviors
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu Jun 18 07:12:00 EDT 2026
    Notes       : Example: Create STOP/QUIT conditions (more TBD)

    DOH Mapping: anomaly.map

    Provides endpoints to demonstrate various anomalous behaviors, including:
        - Disruptive code execution (STOP, QUIT, busy-wait)
        - Resource leaks (memptr, buffer, handle, object)
------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

using {&CLASS_PACKAGE}.Common.Util.FileTools.
using OpenEdge.Core.StringConstant.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.

class {&CLASS_PACKAGE}.Interface.AnomalyService
    use-widget-pool
    final
    :

    // Will be used to demonstrate a hanging buffer.
    define temp-table tt1
        field f1 as character
        .

    // Will be used to demonstrate a lingering object.
    define public property oArray as JsonArray no-undo
        get():
            if not valid-object(oArray) then
                assign oArray = new JsonArray().

            return oArray.
        end get.
        private set.

    /**
        Populates the class-level oArray with 100 sample JsonObject entries.
        Each entry contains an iteration index and a company name string.
        Called internally to build accumulated object state for leak demonstration.
      */
    method private void LoadArray ( ):
        define variable oJsonObj as JsonObject no-undo.
        define variable ix       as integer no-undo.

        do ix = 1 to 100:
            assign oJsonObj = new JsonObject().
            oJsonObj:Add("iteration", ix).
            oJsonObj:Add("company", substitute("Progress: &1", ix)).
            this-object:oArray:Add(cast(oJsonObj:Clone(), JsonObject)).
            delete object oJsonObj no-error.
        end.
    end method. /* LoadPropArray */

    /* Access the service-level logging manager. */
    define protected property oLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.

    /** ***** Public Endpoints ***** */

    /** ***** Disruption Endpoints ***** */

    /**
        Disconnects the current database from this session, causing a reconnection on the next request.
        Exposed as GET /anomaly/disrupt/db/disconnect

        @param logical plResult [OUTPUT] Whether the database was successfully disconnected
      */
    method public void dbDisconnect ( output plResult as logical ):
        if num-dbs eq 1 then
            disconnect value(ldbname(1)) no-error.

        assign plResult = (num-dbs eq 0).
    end method. /* dbDisconnect */

    /**
        Triggers a QUIT condition, terminating the current session agent.
        The output parameter is set in the FINALLY block but should never reach the client.
        Exposed as GET /anomaly/disrupt/code/quit

        @param logical plCompleted [OUTPUT] Whether the method returned normally; expected to be false due to QUIT
      */
    method public void quitCode ( output plCompleted as logical ):
        quit. /* Trigger a quit condition for this code. */

        finally:
            assign plCompleted = true. /* This really should't return with a QUIT. */
        end finally.
    end method. /* quitCode */

    /**
        Triggers a STOP condition, interrupting normal execution flow for the current request.
        The output parameter is set in the FINALLY block but should not reach the client normally.
        Exposed as GET /anomaly/disrupt/code/stop

        @param logical plCompleted [OUTPUT] Whether the method returned normally; expected to be false due to STOP
      */
    method public void stopCode ( output plCompleted as logical ):
        stop. /* Trigger a stop condition for this code. */

        finally:
            assign plCompleted = true. /* This really should't return with a STOP. */
        end finally.
    end method. /* stopCode */

    /** ***** Code Behavior Endpoints ***** */

    /**
        Simulates long-running code by pausing execution for a specified duration.
        Throws a BadRequest error if piBusyTime is negative.
        Exposed as GET /anomaly/disrupt/code/busy

        @param integer piBusyTime [INPUT] Time in milliseconds to stay busy; defaults to 1000 if unknown
        @param integer piElapsed [OUTPUT] Actual piElapsed time in milliseconds measured via interval()
      */
    method public void lookBusy ( input  piBusyTime as integer,
                                  output piElapsed  as integer ):
        /* If no time specified then default to 1000 milliseconds. */
        if piBusyTime eq ? or piBusyTime eq 0 then assign piBusyTime = 1000.

        if piBusyTime lt 0 then /* Throw an error if the provided value is negative; SEE allows changing of the response code. */
            undo, throw new OpenEdge.Web.SendExceptionError(OpenEdge.Net.HTTP.StatusCodeEnum:BadRequest,
                "Busy Time parameter cannot be less than zero.").

        /* Run a wait loop for some period to imitate long-running code. */
        define variable iStart as datetime no-undo.
        assign iStart = now.
        pause (piBusyTime / 1000) no-message.

        finally:
            /* Confirm that execution paused for the time stated. */
            assign piElapsed = interval(now, iStart, "milliseconds").
        end finally.
    end method. /* lookBusy */

    /** ***** Memory Leak Endpoints ***** */

    /**
        Intentionally creates a dataset handle without releasing it to simulate a buffer/handle leak.
        The hDS handle is not deleted, demonstrating lingering handle accumulation.
        Exposed as GET /anomaly/leak/code/buffer

        @param logical plCompleted [OUTPUT] Whether the method plCompleted without error
      */
    method public void badBuffer ( output plCompleted as logical ):
        /* Create a buffer that will not be cleaned up. */
        define variable hDS as handle.

        create dataset hDS.

        assign plCompleted = true.

    /* DO NOT clean up the datasets nor buffer handle. */
    end method. /* badBuffer */

    /**
        Intentionally runs a persistent procedure without cleaning up its handle to simulate a handle leak.
        The hProc persistent procedure handle is not deleted after use.
        Exposed as GET /anomaly/leak/code/handle

        @param character pcMessage [OUTPUT] The message returned from the persistent procedure
      */
    method public void badHandle ( output pcMessage as character ):
        define variable hProc as handle no-undo.

        run OpenEdge/LoadSuite/Sample/HelloProc persistent set hProc.
        run sayHello in hProc ( "World", output pcMessage).

    /* DO NOT clean up the persistent handle, but instead let it linger. */
    end method. /* badHandle */

    /**
        Intentionally allocates a memptr of random size without releasing it to simulate a memory leak.
        set-size() is called but never reset to 0, leaving the allocation active.
        Exposed as GET /anomaly/leak/code/memptr

        @param integer piPointerSize [OUTPUT] The allocated size in bytes of the memory pointer
        @param int64 piPointerValue [OUTPUT] The memory address of the allocated pointer
      */
    method public void badMemptr ( output piPointerSize  as integer,
                                   output piPointerValue as int64 ):
        define variable mPtr as memptr no-undo.

        /* Set a size, but DO NOT reset to 0 after use.*/
        set-size(mPtr) = random(100, 200).
        assign piPointerSize = get-size(mPtr).
        assign piPointerValue = get-pointer-value(mPtr).
    end method. /* badMemptr */

    /**
        Appends 100 JsonObject entries to the class-scoped oArray on each invocation without releasing them.
        Repeated calls grow the array indefinitely, demonstrating an object memory leak.
        Exposed as GET /anomaly/leak/code/object

        @param integer plArrayLength [OUTPUT] The total number of entries in the accumulated JSON array after loading
      */
    method public void badObject ( output plArrayLength as integer ):
        this-object:LoadArray(). /* Add data to the class-scoped array. */
        assign plArrayLength = this-object:oArray:Length.

    /* DO NOT clean up the JSON array created. */
    end method. /* badObject */

    /** ***** OS Process Endpoints ***** */

    /**
        Reads the logging.config file using OS-COMMAND, capturing output via a temp file.
        Exposed as GET /anomaly/files/oscommand/data

        Demonstrates the fork-and-exec memory impact: on Linux/Unix, OS-COMMAND triggers a
        fork() of the parent process before exec()ing the command. fork() copies the parent's
        entire virtual address space (copy-on-write), so the larger the PASOE session agent,
        the more memory the OS must reserve for the operation. On Windows, CreateProcess() is
        used instead and does not exhibit this same memory growth characteristic.

        @param character pcFileContents [OUTPUT] The contents of logging.config as read via OS-COMMAND
      */
    method public void osCommandData ( output pcFileContents as character ):
        var character cConfigPath, cTempFile, cCommand, cLine.

        // Search the PROPATH for the config and return a fully qualified path if found.
        assign cConfigPath = FileTools:GetFullPathname(search("logging.config")).

        // session:temp-directory includes a trailing separator on both platforms.
        assign cTempFile = substitute("&1oscommand_&2.tmp":u, session:temp-directory, string(etime)).

        /**
         * Build and execute the OS-specific command, redirecting output to cTempFile.
         * Each call will fork() the session agent process on Linux before exec()ing the command.
         * On systems with a large agent heap, this can cause a measurable spike in server memory.
         */
        if opsys eq "win32":u then
            assign cCommand = substitute('cmd /c type "&1" > "&2"':u,
                                         replace(cConfigPath, "/":u, StringConstant:BACKSLASH),
                                         replace(cTempFile, "/":u, StringConstant:BACKSLASH)).
        else
            assign cCommand = substitute('cat "&1" > "&2"':u, cConfigPath, cTempFile).

        os-command silent value(cCommand).

        // Verify the temp file was created before attempting to read it.
        file-info:file-name = cTempFile.
        if file-info:full-pathname eq ? then
            undo, throw new Progress.Lang.AppError(substitute("OS-COMMAND produced no output file at '&1'.":u, cTempFile), 0).

        // Read the captured output from the temp file.
        input from value(cTempFile).
        repeat:
            import unformatted cLine.
            assign pcFileContents = pcFileContents + cLine + chr(10).
        end.
        input close.

        finally:
            os-delete value(cTempFile) no-error.
        end finally.
    end method. /* osCommandData */

    /**
        Reads the logging.config file using INPUT-THROUGH, piping output from an OS command.
        Exposed as GET /anomaly/files/inputthrough/data

        Demonstrates the fork-and-exec memory impact: on Linux/Unix, INPUT-THROUGH triggers a
        fork() of the parent process before exec()ing the piped command. fork() copies the parent's
        entire virtual address space (copy-on-write), so the larger the PASOE session agent,
        the more memory the OS must reserve for the operation. On Windows, CreateProcess() is
        used instead and does not exhibit this same memory growth characteristic.

        @param character pcFileContents [OUTPUT] The contents of logging.config as read via INPUT-THROUGH
      */
    method public void inputThroughData ( output pcFileContents as character ):
        var character cConfigPath, cCommand, cLine.

        // Search the PROPATH for the config and return a fully qualified path if found.
        assign cConfigPath = FileTools:GetFullPathname(search("logging.config")).

        /**
         * Build the OS-specific piped command to stream the file contents.
         * Each call will fork() the session agent process on Linux before exec()ing the command.
         * On systems with a large agent heap, this can cause a measurable spike in server memory.
         */
        if opsys eq "win32":u then
            assign cCommand = substitute('cmd /c type "&1"':u,
                                         replace(cConfigPath, "/":u, StringConstant:BACKSLASH)).
        else
            assign cCommand = substitute('cat "&1"':u, cConfigPath).

        // Read file contents through a piped OS command, then close the pipe.
        input through value(cCommand).
        repeat:
            import unformatted cLine.
            assign pcFileContents = pcFileContents + cLine + chr(10).
        end.
        input close.
    end method. /* inputThroughData */

end class.
