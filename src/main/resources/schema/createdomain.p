/*------------------------------------------------------------------------
    File        : createdomain.p
    Purpose     : Create or update a single domain for securing API requests.
    Description : Execute procedure while connected to application databases.
    Author(s)   : Dustin Grau
    Created     : Thu Jun 4 09:06:27 EST 2026
    Notes       : Expects domain/code to be passed as session params.
-------------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

using Progress.Lang.Error from propath.
using OpenEdge.DataAdmin.* from propath.
using OpenEdge.DataAdmin.Error.* from propath.
using OpenEdge.DataAdmin.Lang.Collections.* from propath.

block-level on error undo, throw.

/* NOTICE: Do not use the "@" symbol in any passcodes! */
&global-define DomainType _extsso

var character cSessionParams = "", cEntry = "", cKey = "", cValue = "",
              cDomainName = "", cDomainAccessCode = "", cDomainDescription = "External SSO Domain".
var integer iDB = 0, ix = 0.
var DataAdminService oService.
var IDomain oDomain.

/* ***************************  Main Block  *************************** */

/* Parse SESSION:PARAMETER values in key=value format delimited by semicolons. */
assign cSessionParams = trim(session:parameter).

if (cSessionParams gt "":u) eq true then do:
    do ix = 1 to num-entries(cSessionParams, ";":u):
        assign cEntry = entry(ix, cSessionParams, ";":u).

        if num-entries(cEntry, "=":u) ge 2 then do:
            assign
                cKey   = lc(trim(entry(1, cEntry, "=":u)))
                cValue = trim(substring(cEntry, index(cEntry, "=":u) + 1))
                .

            case cKey:
                when "domain":u or
                when "domainName":u then
                    assign cDomainName = cValue.

                when "accesscode":u or
                when "passcode":u or
                when "domainAccessCode":u then
                    assign cDomainAccessCode = cValue.
            end case.
        end.
    end.
end.

/* Apply defaults when no explicit values were supplied. */
if (cDomainName eq ? or trim(cDomainName) eq "":u) then
    assign cDomainName = "OELS":u.

if (cDomainAccessCode eq ? or trim(cDomainAccessCode) eq "":u) then
    assign cDomainAccessCode = "DevSuite":u.

/* Apply changes to all connected databases. */
do iDB = 1 to num-dbs:
    message substitute("Applying domain '&1' (&2) to &3.":u, cDomainName, "{&DomainType}":u, ldbname(iDB)).
    assign oService = new DataAdminService(ldbname(iDB)).

    if valid-object(oService) then do:
        message substitute("Modifying '&1'.", ldbname(iDB)).

        assign oDomain = oService:GetDomain(cDomainName).
        if valid-object(oDomain) then do:
            /* Update Existing Domain */
            message substitute("Updating Domain &1", cDomainName).
            assign
                oDomain:AccessCode = cDomainAccessCode
                oDomain:Description = cDomainDescription
                .
            oService:UpdateDomain(oDomain).
        end. /* valid-object(oDomain) */
        else do:
            /* Create New Domain */
            message substitute("Creating Domain &1", cDomainName).
            assign
                oDomain = oService:NewDomain(cDomainName)
                oDomain:AuthenticationSystem = oService:GetAuthenticationSystem("{&DomainType}")
                oDomain:AccessCode = cDomainAccessCode
                oDomain:Description = cDomainDescription
                oDomain:IsEnabled = true
                .
            oService:CreateDomain(oDomain).
        end. /* not valid-object(oDomain) */

        delete object oService.
    end. /* valid-object(oService) */
end. /* iDB */

catch e as Error:
    define variable errorHandler as DataAdminErrorHandler no-undo.
    errorHandler = new DataAdminErrorHandler().
    errorHandler:Error(e).
end catch.
finally:
    delete object oDomain no-error.
end finally.
