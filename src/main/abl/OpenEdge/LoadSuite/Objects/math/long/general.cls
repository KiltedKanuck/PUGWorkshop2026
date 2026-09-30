 
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
 * General INT64 math utilities.
 *
 * Provides basic arithmetic operations implemented in ABL for INT64 operands.
 * All methods run under `BLOCK-LEVEL ON ERROR UNDO, THROW`, so runtime errors
 * (for example, division by zero) will raise `Progress.Lang.Error` unless handled
 * by callers.
 *
 * @author Cameron David Wright <openedge>
 * @since 1.0
 * @version 1.0
 */
CLASS OpenEdge.LoadSuite.Objects.math.long.general: 
        
    /**
     * Initializes a new instance of `OpenEdge.LoadSuite.Objects.math.long.general`.
     *
     * No state is maintained; construction is effectively a no-op beyond base initialization.
     */
    CONSTRUCTOR PUBLIC general (  ):
        SUPER ().
        
    END CONSTRUCTOR.

    /**
     * Adds two INT64 values.
     *
     * @param iNum1 First addend.
     * @param iNum2 Second addend.
     * @return Sum of `iNum1` and `iNum2`.
     * @throws Progress.Lang.Error If an arithmetic error occurs.
     */
    METHOD PUBLIC INT64 addition( INPUT iNum1 AS INT64, INPUT iNum2 AS INT64 ):
        
        DEFINE VARIABLE result AS INT64 NO-UNDO.

        ASSIGN result = (iNum1 + iNum2).

        RETURN result.

    END METHOD.

    /**
     * Subtracts the second INT64 from the first.
     *
     * @param iNum1 Minuend.
     * @param iNum2 Subtrahend.
     * @return Difference `iNum1 - iNum2`.
     * @throws Progress.Lang.Error If an arithmetic error occurs.
     */
    METHOD PUBLIC INT64 subtraction(  INPUT iNum1 AS INT64, INPUT iNum2 AS INT64  ):
        
        DEFINE VARIABLE result AS INT64 NO-UNDO.

        ASSIGN result = (iNum1 - iNum2).

        RETURN result.

    END METHOD.

    /**
     * Multiplies two INT64 values.
     *
     * @param iNum1 Multiplicand.
     * @param iNum2 Multiplier.
     * @return Product `iNum1 * iNum2`.
     * @throws Progress.Lang.Error If an arithmetic error occurs.
     */
    METHOD PUBLIC INT64 multiplication(  INPUT iNum1 AS INT64, INPUT iNum2 AS INT64  ):
        
        DEFINE VARIABLE result AS INT64 NO-UNDO.

        ASSIGN result = (iNum1 * iNum2).

        RETURN result.

    END METHOD.
    
    /**
     * Divides the first INT64 by the second.
     *
     * Note: Division by zero will raise an error under the class error policy.
     *
     * @param iNum1 Dividend.
     * @param iNum2 Divisor.
     * @return Quotient `iNum1 / iNum2`.
     * @throws Progress.Lang.Error If `iNum2` is zero or another arithmetic error occurs.
     */
    METHOD PUBLIC INT64 division(  INPUT iNum1 AS INT64, INPUT iNum2 AS INT64  ):
        
        DEFINE VARIABLE result AS INT64 NO-UNDO.

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