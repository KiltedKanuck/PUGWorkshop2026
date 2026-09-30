 
 /*------------------------------------------------------------------------
    File        : TestStringLongGeneral.p 
    Syntax      : 
    Author(s)   : Cameron David Wright
    Created     : Tue Dec 06 16:11:46 UTC 2022
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using OpenEdge.Core.Assert.

block-level on error undo, throw.

define variable hProc       as handle no-undo.
define variable testSize    as int64 no-undo.
define variable testString  as longchar no-undo.


@Before.
procedure setUpBeforeProcedure:

    run "Procedure\string\long\general.p" persistent set hProc no-error.
    this-procedure:add-super-procedure(hProc).
    
    run getData (output testSize, output testString).

end procedure. 

@After.
procedure tearDownAfterProcedure: 

    delete object hProc no-error.
    assign hProc = ?.

end procedure. 

@Test.
procedure TestWhatLetter:
    define variable kLocal      as character no-undo.
    define variable TestReturn  as character no-undo.
    define variable iRandLetter as integer no-undo.
    
    assign
        iRandLetter = 5
        kLocal = substring(testString,iRandLetter,1)
        .
    
    run WhatLetter(iRandLetter, output testReturn).
    
    Assert:Equals(TestReturn,kLocal).

    return.
    
end procedure.

@Test.
procedure TestWhat5Letter:
    define variable kLocal      as character no-undo.
    define variable TestReturn  as character no-undo.
    define variable iRandLetter as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 5 no-undo.
    
    do iLoop = 1 to iMax:
        assign
            iRandLetter = ((iLoop - 1) MOD (testSize - 1)) + 1
            kLocal = substring(testString,iRandLetter,1)
            testReturn = ""
            .
        
        run WhatLetter(iRandLetter, output testReturn).
        
        Assert:Equals(TestReturn,kLocal).
    end.
    
    return.
    
end procedure.
@Test.
procedure TestWhat25Letter:
    define variable kLocal      as character no-undo.
    define variable TestReturn  as character no-undo.
    define variable iRandLetter as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 25 no-undo.
    
    do iLoop = 1 to iMax:
        assign
            iRandLetter = ((iLoop - 1) MOD (testSize - 1)) + 1
            kLocal = substring(testString,iRandLetter,1)
            testReturn = ""
            .
        
        run WhatLetter(iRandLetter, output testReturn).
        
        Assert:Equals(TestReturn,kLocal).
    end.
    
    return.
    
end procedure.

@Test.
procedure TestWhat50Letter:
    define variable kLocal      as character no-undo.
    define variable TestReturn  as character no-undo.
    define variable iRandLetter as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 50 no-undo.
    
    do iLoop = 1 to iMax:
        assign
            iRandLetter = ((iLoop - 1) MOD (testSize - 1)) + 1
            kLocal = substring(testString,iRandLetter,1)
            testReturn = ""
            .
        
        run WhatLetter(iRandLetter, output testReturn).
        
        Assert:Equals(TestReturn,kLocal).
    end.
    
    return.
    
end procedure.
@Test.
procedure TestWhat500Letter:
    define variable kLocal      as character no-undo.
    define variable TestReturn  as character no-undo.
    define variable iRandLetter as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 500 no-undo.
    
    do iLoop = 1 to iMax:
        assign
            iRandLetter = ((iLoop - 1) MOD (testSize - 1)) + 1
            kLocal = substring(testString,iRandLetter,1)
            testReturn = ""
            .
        
        run WhatLetter(iRandLetter, output testReturn).
        
        Assert:Equals(TestReturn,kLocal).
    end.
    
    return.
    
end procedure.

@Test.
procedure TestWhatWord:
    define variable TestReturn  as character no-undo.
    define variable iLoc        as integer no-undo.
    define variable iLength     as integer no-undo.
    
    assign
        iLength = 25
        iLoc = 30
        .

    run WhatWord(iLoc, iLength, output TestReturn).
    
    Assert:Equals(TestReturn, substring(testString,iLoc,iLength) ).

    return.
    
end procedure.

@Test.
procedure TestWhat5Word:
    define variable TestReturn  as character no-undo.
    define variable iLoc        as integer no-undo.
    define variable iLength     as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 5 no-undo.

    do iLoop = 1 to iMax:    
        assign
            iLength = 20 + ((iLoop - 1) MOD 10)
            iLoc = 30 + ((iLoop - 1) MOD 20)
            testReturn = ""
            .
    
        run WhatWord(iLoc, iLength, output TestReturn).
        
        Assert:Equals(TestReturn, substring(testString,iLoc,iLength) ).
    end.
    return.
    
end procedure.
@Test.
procedure TestWhat25Word:
    define variable TestReturn  as character no-undo.
    define variable iLoc        as integer no-undo.
    define variable iLength     as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 25 no-undo.

    do iLoop = 1 to iMax:    
        assign
            iLength = 20 + ((iLoop - 1) MOD 10)
            iLoc = 30 + ((iLoop - 1) MOD 20)
            testReturn = ""
            .
    
        run WhatWord(iLoc, iLength, output TestReturn).
        
        Assert:Equals(TestReturn, substring(testString,iLoc,iLength) ).
    end.
    return.
    
end procedure.
@Test.
procedure TestWhat50Word:
    define variable TestReturn  as character no-undo.
    define variable iLoc        as integer no-undo.
    define variable iLength     as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 50 no-undo.

    do iLoop = 1 to iMax:    
        assign
            iLength = 20 + ((iLoop - 1) MOD 10)
            iLoc = 30 + ((iLoop - 1) MOD 20)
            testReturn = ""
            .
    
        run WhatWord(iLoc, iLength, output TestReturn).
        
        Assert:Equals(TestReturn, substring(testString,iLoc,iLength) ).
    end.
    return.
    
end procedure.
@Test.
procedure TestWhat500Word:
    define variable TestReturn  as character no-undo.
    define variable iLoc        as integer no-undo.
    define variable iLength     as integer no-undo.
    define variable iloop       as integer no-undo.
    define variable iMax        as integer initial 500 no-undo.

    do iLoop = 1 to iMax:    
        assign
            iLength = 20 + ((iLoop - 1) MOD 10)
            iLoc = 30 + ((iLoop - 1) MOD 20)
            testReturn = ""
            .
    
        run WhatWord(iLoc, iLength, output TestReturn).
        
        Assert:Equals(TestReturn, substring(testString,iLoc,iLength) ).
    end.
    return.
    
end procedure.
