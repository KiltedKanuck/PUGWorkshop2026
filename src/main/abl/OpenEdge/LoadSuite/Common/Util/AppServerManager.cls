/*------------------------------------------------------------------------------
  File    : AppServerManager.cls
  Purpose : AppServer connection manager.
  Usage   :
------------------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class OpenEdge.LoadSuite.Common.Util.AppServerManager:

    var private static handle hAppServer = ?.
    var private static character cHost = "127.0.0.1", cPort = "7780", cWebApp = "LoadSuite".

    define public static property Instance as OpenEdge.LoadSuite.Common.Util.AppServerManager no-undo
    get():
        if not valid-object(Instance) then
            OpenEdge.LoadSuite.Common.Util.AppServerManager:Instance = new OpenEdge.LoadSuite.Common.Util.AppServerManager().

        return Instance.
    end get.
    private set.

    constructor private AppServerManager ():
        // Private constructor, prevent direct instantiation.
    end constructor.

    destructor public AppServerManager ():
        if valid-object(hAppServer) then do:
            hAppServer:disconnect() no-error.
            delete object hAppServer no-error.
            hAppServer = ?.
        end.
    end destructor.

    method private logical CheckConnection ():
        var character cConnectString = "".
        var logical lConnected = false.

        if valid-object(hAppServer) and hAppServer:connected() then
            return true. // If valid server handle and connected, we're good.

        if valid-object(hAppServer) then do:
            // If not connected, clean up the handle before trying to reconnect.
            hAppServer:disconnect() no-error.
            delete object hAppServer no-error.
            hAppServer = ?.
        end.

        create server hAppServer.
        assign cConnectString = substitute("-URL http://&1:&2/&3/apsv -sessionModel session-free", cHost, cPort, cWebApp).
        assign lConnected = hAppServer:connect(cConnectString) no-error.

        if error-status:error then do:
            message substitute("Error connecting to AppServer: &1", error-status:get-message(1)).
            error-status:error = false.
            return false.
        end.

        if not lConnected or not valid-object(hAppServer) then do:
            delete object hAppServer no-error.
            hAppServer = ?.
            return false.
        end.

        return true.
    end method.

end class.
