/*------------------------------------------------------------------------
    File        : HybridRealm
    Purpose     : Provide Tomcat access to application auth data
    Description : Customized OERealm authentication
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Apr 5 14:47:00 EST 2026
    Notes       :

    By default all methods will return a successful result from OEUserRealm.
    Only override methods that need an alternative or custom result.
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

class {&CLASS_PACKAGE}.Security.Realm.HybridRealm
    inherits {&CLASS_PACKAGE}.Security.OEUserRealm
    final:

    method public override integer getUserID ( input pcUsername   as character,
                                               input pcDomainName as character ):
        // For the k6 tests the virtual users will use a suffix of "-#" on the username.
        // We should extract that to use as the internal UserID for improved logging.
        var integer iLastDashPos = r-index(pcUsername, "-"), iUserID = 0.
        var character cTempUserID = "".

        if iLastDashPos eq 0 then
            return length(pcUsername, "character").

        assign cTempUserID = substring(pcUsername, iLastDashPos + 1).
        if cTempUserID eq "" then
            return length(pcUsername, "character").

        assign iUserID = integer(cTempUserID) no-error.
        if error-status:error then
            return length(pcUsername, "character").

        return iUserID.
    end method. // getUserID

    method public override character getUserRoles ( input piUserID as integer ):
        // This is the critical part that is ONLY for Anonymous access.
        if piUserID eq 0 then return "ANONYMOUS".

        // Return some default roles for all "authenticated" users.
        return "DevUser,AuthenticatedUser".
    end method. // getUserRoles

    method protected override void postAuthenticate ( input piUserID as integer,
                                                      input lRetVal  as logical ):
        // Note this user's success/failure to authenticate.
        oLogger:Info(substitute("postAuthenticate: UserID: &1, Result: &2", piUserID, trim(string(lRetVal, "SUCCESS/FAILURE")))).
    end method. // postAuthenticate

end class.