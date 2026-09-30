/**
 * Sanity check test class for basic environment validation.
 * Verifies that basic runtime environment is properly configured.
 */

block-level on error undo, throw.

using OpenEdge.Core.Assert.

class Sanity:

    /**
     * Sanity check: verify PROPATH is configured and not empty.
     * This is a basic validation that the environment is set up correctly.
     */
    @Test.
    method public void PROPATHIsConfigured( ):
        define variable cPropath as character no-undo.
        
        assign cPropath = propath.
        
        Assert:IsTrue(cPropath > "", "PROPATH Present").
    end method.

end class.
