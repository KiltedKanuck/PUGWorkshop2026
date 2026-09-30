/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : CatalogService
    Purpose     : Returns an OpenAPI catalog for DOH services
    Description :
    Author(s)   : Dustin Grau
    Created     : Tue Jul 16 11:34:04 EDT 2024
    Notes       : Depends on new logic which was introduced in OpenEdge 13
    to allow for OpenAPI spec 3.1 and 3.2 output, which will eventually be
    merged back to the OpenEdge 12.8.x release. For now, include the code
    included in the OpenEdge/Web folder if using in a similar project.

    DOH Mapping: catalog.map
------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.PUG

using {&CLASS_PACKAGE}.Common.Util.FileTools.
using OpenEdge.Core.SemanticVersion.
using OpenEdge.Core.StringConstant.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LogFilterBuilderRegistry.
using OpenEdge.Logging.LoggerBuilder.
using OpenEdge.Logging.LoggerFilterRegistry.
using OpenEdge.Net.HTTP.Filter.Writer.BodyWriterRegistry.
using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterRegistry.
using OpenEdge.Web.DataObject.ServiceRegistry.
using OpenEdge.Web.DataObject.Writer.ArgumentValueWriterRegistry.
using OpenEdge.Web.DataObject.Writer.IOpenAPIServiceWriter.
using OpenEdge.Web.DataObject.Writer.OpenAPI31ServiceWriter.
using OpenEdge.Web.DataObject.Writer.OperationHandlerRegistry.
using OpenEdge.Web.DataObject.Writer.ResponseElementWriterRegistry.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.ObjectModelParser.

class {&CLASS_PACKAGE}.Interface.CatalogService
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

    /* Tracks the last time the CB props file was loaded from the file system. */
    var protected datetime dCBPropsLastLoaded = ?.

    /* Find a better default port in use with this instance. */
    var protected integer iPort.

    /* Version for the application document. */
    var private SemanticVersion oApiVersion.

    constructor CatalogService ( ):
        // Define the API version for this application.
        assign oApiVersion = new SemanticVersion(0, 0, 0).

        this-object:Discovery(). /* Perform local discovery of server info. */
        this-object:GetAppVersion(). /* Get the application version info. */
    end constructor.

    method protected void Discovery ( ):
        var character cLine, cFilePath, cSvcMapPath.
        var longchar lcConfigTemp.
        var integer iLine, iLines, iHttpPort, iHttpsPort.
        var datetime dLastDate.

        oLogger:Debug(substitute("Performing Discovery; CATALINA_BASE: &1":u, FileTools:GetCatalinaBase())).

        /* Examine the catalina.properties for info about the available ports. */
        file-info:file-name = substitute("&1/conf/catalina.properties":u, FileTools:GetCatalinaBase()).
        assign cFilePath = file-info:full-pathname.
        if cFilePath ne ? then do:
            /* Get the current date/time that the file was last modified. */
            assign dLastDate = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).

            if dLastDate ne dCBPropsLastLoaded then do:
                /* Mark down the current modified date/time for this file. */
                assign dCBPropsLastLoaded = dLastDate.

                /* Read the file into a longchar value (avoids keeping the file open). */
                copy-lob from file cFilePath to lcConfigTemp no-error.

                assign iLines = num-entries(lcConfigTemp, "~n").
                if iLines ge 1 then cfgblk:
                do iLine = 1 to iLines:
                    assign cLine = trim(entry(iLine, lcConfigTemp, "~n")).

                    case true:
                        when cLine begins "psc.as.http.port=":u then
                            assign iHttpPort = integer(trim(entry(2, cLine, "="))).
                        when cLine begins "psc.as.https.port=":u then
                            assign iHttpsPort = integer(trim(entry(2, cLine, "="))).
                    end case.
                end. /* do iLines */

                /* Look to the same server at either the HTTP or HTTPS port for OEManager. */
                if iHttpPort gt 0 then
                    assign iPort = iHttpPort.
                else if iHttpsPort gt 0 then
                    assign iPort = iHttpsPort.

                assign lcConfigTemp = ?. /* Reset the variable. */
            end. /* file updated */
        end. /* catalina.properties */

        /* Start some of the internal registries by accessing the static properties. */
        ArgumentValueWriterRegistry:Registry.
        BodyWriterRegistry:Registry.
        EntityWriterRegistry:Registry.
        LogFilterBuilderRegistry:Registry.
        LoggerFilterRegistry:Registry.
        OperationHandlerRegistry:Registry.
        ResponseElementWriterRegistry:Registry.
        ServiceRegistry:Registry.

        /**
         * By default the ServiceRegistry will only be populated with data as a service is utilized.
         * We need to speed up this process to have all the services available for display, which
         * requires us to load all services available. This will be assumed to be in the same folder
         * in the PROPATH which contains our catalog.map file.
         */
        file-info:file-name = "catalog.map":u. /* Try looking for a catalog.map file on disk. */
        if file-info:full-pathname ne ? then /* When file is present, obtain the base path of the file. */
            assign cSvcMapPath = replace(substring(file-info:full-pathname, 1, length(file-info:full-pathname) - length(file-info:file-name)), "~\", "/").

        oLogger:Debug(substitute("Service Map Path to '&1': &2":u, file-info:file-name, cSvcMapPath)).

        if (cSvcMapPath gt "") eq true then
            ServiceRegistry:RegisterAllFromFolder(cSvcMapPath). /* Load all services found in this folder. */

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("Error in Discovery: &1":u, err:GetMessage(1))).
        end catch.
    end method. // Discovery


    method private void GetAppVersion ( ):
        var ObjectModelParser oParser = new ObjectModelParser().
        var character cFilePath, cVersion.
        var JsonObject oVersion.

        oLogger:Debug("Checking for 'version.json' in ABL Application PROPATH...":u).

        /* Extract the version info from the JSON file and parse into a SemanticVersion object. */
        file-info:file-name = search("version.json":u).
        assign cFilePath = file-info:full-pathname.
        if cFilePath ne ? then do:
            assign oVersion = cast(oParser:ParseFile(cFilePath), JsonObject).

            if valid-object(oVersion) and oVersion:Has("version") then
                assign cVersion = oVersion:GetCharacter("version").

            if (cVersion gt "") eq true then
                assign oApiVersion = SemanticVersion:Parse(cVersion).
        end.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("Error obtaining version info: &1ms":u, err:GetMessage(1))).
        end catch.
        finally:
            delete object oParser no-error.
            delete object oVersion no-error.
        end finally.
    end method. /* GetAppVersion */

    /**
     * Get the scheme (protocol) from the current web request
     * Checks HTTPS and REQUEST_SCHEME CGI environment variables
     * Returns "http" or "https" based on the request
     */
    method protected character GetScheme ( ):
        var character cScheme, cHttps.

        // Check if HTTPS is enabled via the HTTPS CGI variable
        assign cHttps = web-context:get-cgi-value("env":u, "HTTPS":u).
        if cHttps eq "on":u or cHttps eq "1":u then
            return "https":u.

        // Check REQUEST_SCHEME if available
        assign cScheme = web-context:get-cgi-value("env":u, "REQUEST_SCHEME":u).
        if cScheme eq "https":u then
            return "https":u.

        // Default to http
        return "http":u.
    end method. // GetScheme

    /**
     * Get the hostname from the current web request
     * Extracts SERVER_NAME from the CGI environment variables
     * Returns "localhost" as fallback if not available
     */
    method protected character GetHostname ( ):
        var character cHostname.

        // Get the server name from the web request CGI variables
        assign cHostname = web-context:get-cgi-value("env":u, "SERVER_NAME":u).

        // Return localhost as fallback if hostname not available
        if (cHostname gt "") ne true then
            assign cHostname = "localhost":u.

        return cHostname.
    end method. // GetHostname

    /**
     * Get the context path (webapp) from the current web request
     * Extracts CONTEXT_PATH from the CGI environment variables
     * Returns "" as fallback if not available
     */
    method protected character GetContext ( ):
        var character cContext.

        // Get the context path from the web request CGI variables
        assign cContext = web-context:get-cgi-value("env":u, "CONTEXT_PATH":u).

        // Return empty string (for ROOT) as fallback if context path not available
        if (cContext gt "") ne true then
            assign cContext = "":u.

        return cContext.
    end method. // GetContext

    /** ***** Public Endpoints ***** */

    /**
     * Returns an object as {"response":{"_retVal":true}}
     */
    method public void GetPingResponse ( output pingResponse as JsonObject ):
        assign pingResponse = new JsonObject().

        pingResponse:Add("response":u, new JsonObject()).
        pingResponse:GetJsonObject("response":u):Add("_retVal":u, true).
        if can-do("true,yes,1", trim(os-getenv("OELS_USE_CUSTOM_PING":u))) then
            pingResponse:GetJsonObject("response":u):Add("_hostname":u, trim(os-getenv("OELS_PING_HOST":u))).
        pingResponse:GetJsonObject("response":u):Add("version":u, oApiVersion:ToString()).

        catch err as Progress.Lang.Error:
            oLogger:Error("Error generating ping response":u, err).
            if session:error-stack-trace then
                oLogger:Error(err:CallStack).
        end catch.
    end method. // GetPingResponse

    /**
     * Return a JSON object with an Open API v3.0 formatted description of resource endpoints.
     * This utilizes the static ServiceRegistry created at first use of the WEB-based service.
     */
    method public void GetOpenApiCatalog ( output catalog as JsonObject ):
        var IOpenAPIServiceWriter oServiceWriter.
        var character cScheme = "http":u, cHostname = "localhost":u, cDefaultContext = "":u, cDefaultBasePath = "":u.

        // Get the hostname and scheme used to reach this server.
        assign
            cScheme          = this-object:GetScheme()
            cHostname        = this-object:GetHostname()
            cDefaultContext  = this-object:GetContext()
            cDefaultBasePath = "/" + OpenEdge.Web.DataObject.DataObjectHandler:HANDLER_PREFIX
            .

        // Always create a new service writer instance with the current context.
        assign oServiceWriter = new OpenAPI31ServiceWriter().
        if valid-object(oServiceWriter) then do:
            // Open() applies the user context and creates the structure.
            oServiceWriter:SetDocumentVersion(oApiVersion:ToString())
                          :SetServer(cScheme, cHostname, iPort, cDefaultContext, cDefaultBasePath)
                          :Open().

            // Write all available services and Close as normal.
            oServiceWriter:Write(ServiceRegistry:GetServices()).
            oServiceWriter:Close().

            // Cast the resulting JSON object from the service writer.
            assign catalog = cast(oServiceWriter:Value, JsonObject).
        end.

        /* Return an empty object if catalog object is invalid. */
        if not valid-object(catalog) then
            assign catalog = new JsonObject().

        catch err as Progress.Lang.Error:
            oLogger:Error("Unable to get OpenAPI catalog":u, err).
            if session:error-stack-trace then
                oLogger:Error(err:CallStack).
        end catch.
        finally:
            delete object oServiceWriter no-error.
        end finally.
    end method. // GetOpenApiCatalog

end class.