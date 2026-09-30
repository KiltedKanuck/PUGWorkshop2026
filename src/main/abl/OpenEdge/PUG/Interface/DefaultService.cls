block-level on error undo, throw.

&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.PUG

using {&CLASS_PACKAGE}.Common.Util.FileTools.

using OpenEdge.Core.StringConstant.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.

class {&CLASS_PACKAGE}.Interface.DefaultService
    use-widget-pool
    final
    :

    method public void Hello ( output pcMessage as character ):
        define variable hProc as handle no-undo.

        run OpenEdge/PUG/Sample/HelloProc persistent set hProc.
        run sayHello in hProc ( "World", output pcMessage).

        delete object hProc.
    
    end method.

end class.