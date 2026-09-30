 /*------------------------------------------------------------------------
    File        : general
    Purpose     : Execute and measure performance of OpenEdge MATH functions
    Description : General math functions    
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/**
 * General INTEGER math utilities.
 *
 * Provides basic arithmetic operations implemented in ABL for INTEGER operands.
 * All methods run under `BLOCK-LEVEL ON ERROR UNDO, THROW`, so runtime errors
 * (for example, division by zero) will raise `Progress.Lang.Error` unless handled
 * by callers.
 *
 * @author Cameron David Wright <openedge>
 * @since 1.0
 * @version 1.0
 */
CLASS OpenEdge.LoadSuite.Objects.math.integer.general: 
        
    /**
     * Initializes a new instance of `OpenEdge.LoadSuite.Objects.math.integer.general`.
     *
     * No state is maintained; construction is effectively a no-op beyond base initialization.
     */
    CONSTRUCTOR PUBLIC general (  ):
        SUPER ().
        
    END CONSTRUCTOR.

    /**
     * Adds two INTEGER values.
     *
     * @param iNum1 First addend.
     * @param iNum2 Second addend.
     * @return Sum of `iNum1` and `iNum2`.
     * @throws Progress.Lang.Error If an arithmetic error occurs.
     */
    METHOD PUBLIC INTEGER addition( INPUT iNum1 AS INTEGER, INPUT iNum2 AS INTEGER ):
        
        DEFINE VARIABLE result AS INTEGER NO-UNDO.

        ASSIGN result = (iNum1 + iNum2).

        RETURN result.

    END METHOD.

    /**
     * Subtracts the second INTEGER from the first.
     *
     * @param iNum1 Minuend.
     * @param iNum2 Subtrahend.
     * @return Difference `iNum1 - iNum2`.
     * @throws Progress.Lang.Error If an arithmetic error occurs.
     */
    METHOD PUBLIC INTEGER subtraction(  INPUT iNum1 AS INTEGER, INPUT iNum2 AS INTEGER  ):
        
        DEFINE VARIABLE result AS INTEGER NO-UNDO.

        ASSIGN result = (iNum1 - iNum2).

        RETURN result.

    END METHOD.

    /**
     * Multiplies two INTEGER values.
     *
     * @param iNum1 Multiplicand.
     * @param iNum2 Multiplier.
     * @return Product `iNum1 * iNum2`.
     * @throws Progress.Lang.Error If an arithmetic error occurs.
     */
    METHOD PUBLIC INTEGER multiplication(  INPUT iNum1 AS INTEGER, INPUT iNum2 AS INTEGER  ):
        
        DEFINE VARIABLE result AS INTEGER NO-UNDO.

        ASSIGN result = (iNum1 * iNum2).

        RETURN result.

    END METHOD.
    
    /**
     * Divides the first INTEGER by the second.
     *
     * Note: Division by zero will raise an error under the class error policy.
     *
     * @param iNum1 Dividend.
     * @param iNum2 Divisor.
     * @return Quotient `iNum1 / iNum2`.
     * @throws Progress.Lang.Error If `iNum2` is zero or another arithmetic error occurs.
     */
    METHOD PUBLIC INTEGER division(  INPUT iNum1 AS INTEGER, INPUT iNum2 AS INTEGER  ):
        
        DEFINE VARIABLE result AS INTEGER NO-UNDO.

        ASSIGN result = (iNum1 / iNum2).

        RETURN result.

    END METHOD.
        
    /**
     * Releases resources held by this instance.
     *
     * No explicit cleanup is required for this stateless class.
     */
    DESTRUCTOR PUBLIC general ( ):

    END DESTRUCTOR.

END CLASS.