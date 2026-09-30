/*------------------------------------------------------------------------
    File        : IAuthHandler
    Purpose     : Provides specific methods for checking user credentials
    Description : Basic helper methods for authentication by IHybridRealm
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Apr 5 14:42:00 EST 2026
    Notes       :
  ----------------------------------------------------------------------*/

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

interface {&CLASS_PACKAGE}.Security.IAuthHandler:

    /**
     * The following protected variables are available for use:
     *
     * define protected variable oConfig   as ConfigMessage no-undo.
     * define protected variable useDebugs as logical       no-undo initial false.
     *
     * The following are protected methods that can be overriden, but cannot be included as interface definitions:
     *
     * method protected logical checkPasswordHash ( input pcPassword as character, input pcHashPass as character ).
     * method protected logical checkPasswordHash ( input piUserID   as integer, input pcPassword as character, input pcHashPass as character ).
     * method protected character getPassword ( input piUserID as integer ).
     * method protected void postAuthenticate ( input piUserID as integer, input lRetVal  as logical ).
     */

    method integer getUserID ( input pcUsername   as character,
                               input pcDomainName as character ).

    method logical isActive ( input piUserID as integer ).

    method logical isExpired ( input piUserID as integer ).

    method logical isLocked ( input piUserID as integer ).

    method character getUserRoles ( input piUserID as integer ).

end interface.