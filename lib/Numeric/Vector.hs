{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Numeric.Vector
-- Copyright   :  (c) Alberto Ruiz 2010
-- License     :  GPL-style
--
-- Maintainer  :  Alberto Ruiz <aruiz@um.es>
-- Stability   :  provisional
-- Portability :  portable
--
-- Numeric instances and functions for 'Vector'.
--
-- Provides instances of standard classes 'Show', 'Read', 'Eq',
-- 'Num', 'Fractional',  and 'Floating' for 'Vector'.
-- 
-----------------------------------------------------------------------------

module Numeric.Vector (
    -- * Basic vector functions
    module Data.Packed.Vector,
    module Numeric.Container,
    -- * Vector creation
    constant, linspace,
    -- * Operators
    (<.>)
                      ) where

import Data.Packed.Vector
import Data.Packed.Internal.Matrix
import Numeric.GSL.Vector
import Numeric.Container

-------------------------------------------------------------------

#ifndef VECTOR
import Foreign(Storable)
#endif

------------------------------------------------------------------

#ifndef VECTOR

instance (Show a, Storable a) => (Show (Vector a)) where
    show v = (show (dim v))++" |> " ++ show (toList v)

#endif

#ifdef VECTOR

instance (Element a, Read a) => Read (Vector a) where
    readsPrec _ s = [(fromList . read $ listnums, rest)]
        where (thing,trest) = breakAt ']' s
              (dims,listnums) = breakAt ' ' (dropWhile (==' ') thing)
              rest = drop 31 trest
#else

instance (Element a, Read a) => Read (Vector a) where
    readsPrec _ s = [((d |>) . read $ listnums, rest)]
        where (thing,rest) = breakAt ']' s
              (dims,listnums) = breakAt '>' thing
              d = read . init . fst . breakAt '|' $ dims

#endif

breakAt c l = (a++[c],tail b) where
    (a,b) = break (==c) l

------------------------------------------------------------------

{- | creates a vector with a given number of equal components:

@> constant 2 7
7 |> [2.0,2.0,2.0,2.0,2.0,2.0,2.0]@
-}
constant :: Element a => a -> Int -> Vector a
-- constant x n = runSTVector (newVector x n)
constant = constantD -- about 2x faster

{- | Creates a real vector containing a range of values:

@\> linspace 5 (-3,7)
5 |> [-3.0,-0.5,2.0,4.5,7.0]@

Logarithmic spacing can be defined as follows:

@logspace n (a,b) = 10 ** linspace n (a,b)@
-}
linspace :: (Enum e, Container Vector e) => Int -> (e, e) -> Vector e
linspace n (a,b) = addConstant a $ scale s $ fromList [0 .. fromIntegral n-1]
    where s = (b-a)/fromIntegral (n-1)

-- | Dot product: @u \<.\> v = dot u v@
(<.>) :: Product t => Vector t -> Vector t -> t
infixl 7 <.>
(<.>) = dot

------------------------------------------------------------------

adaptScalar f1 f2 f3 x y
    | dim x == 1 = f1   (x@>0) y
    | dim y == 1 = f3 x (y@>0)
    | otherwise = f2 x y

------------------------------------------------------------------

#ifndef VECTOR

instance Container Vector a => Eq (Vector a) where
    (==) = equal

#endif

instance Num (Vector Float) where
    (+) = adaptScalar addConstant add (flip addConstant)
    negate = scale (-1)
    (*) = adaptScalar scale mul (flip scale)
    signum = vectorMapF Sign
    abs = vectorMapF Abs
    fromInteger = fromList . return . fromInteger

instance Num (Vector Double) where
    (+) = adaptScalar addConstant add (flip addConstant)
    negate = scale (-1)
    (*) = adaptScalar scale mul (flip scale)
    signum = vectorMapR Sign
    abs = vectorMapR Abs
    fromInteger = fromList . return . fromInteger

instance Num (Vector (Complex Double)) where
    (+) = adaptScalar addConstant add (flip addConstant)
    negate = scale (-1)
    (*) = adaptScalar scale mul (flip scale)
    signum = vectorMapC Sign
    abs = vectorMapC Abs
    fromInteger = fromList . return . fromInteger

instance Num (Vector (Complex Float)) where
    (+) = adaptScalar addConstant add (flip addConstant)
    negate = scale (-1)
    (*) = adaptScalar scale mul (flip scale)
    signum = vectorMapQ Sign
    abs = vectorMapQ Abs
    fromInteger = fromList . return . fromInteger

---------------------------------------------------

instance (Container Vector a, Num (Vector a)) => Fractional (Vector a) where
    fromRational n = fromList [fromRational n]
    (/) = adaptScalar f divide g where
        r `f` v = scaleRecip r v
        v `g` r = scale (recip r) v

-------------------------------------------------------

instance Floating (Vector Float) where
    sin   = vectorMapF Sin
    cos   = vectorMapF Cos
    tan   = vectorMapF Tan
    asin  = vectorMapF ASin
    acos  = vectorMapF ACos
    atan  = vectorMapF ATan
    sinh  = vectorMapF Sinh
    cosh  = vectorMapF Cosh
    tanh  = vectorMapF Tanh
    asinh = vectorMapF ASinh
    acosh = vectorMapF ACosh
    atanh = vectorMapF ATanh
    exp   = vectorMapF Exp
    log   = vectorMapF Log
    sqrt  = vectorMapF Sqrt
    (**)  = adaptScalar (vectorMapValF PowSV) (vectorZipF Pow) (flip (vectorMapValF PowVS))
    pi    = fromList [pi]

-------------------------------------------------------------

instance Floating (Vector Double) where
    sin   = vectorMapR Sin
    cos   = vectorMapR Cos
    tan   = vectorMapR Tan
    asin  = vectorMapR ASin
    acos  = vectorMapR ACos
    atan  = vectorMapR ATan
    sinh  = vectorMapR Sinh
    cosh  = vectorMapR Cosh
    tanh  = vectorMapR Tanh
    asinh = vectorMapR ASinh
    acosh = vectorMapR ACosh
    atanh = vectorMapR ATanh
    exp   = vectorMapR Exp
    log   = vectorMapR Log
    sqrt  = vectorMapR Sqrt
    (**)  = adaptScalar (vectorMapValR PowSV) (vectorZipR Pow) (flip (vectorMapValR PowVS))
    pi    = fromList [pi]

-------------------------------------------------------------

instance Floating (Vector (Complex Double)) where
    sin   = vectorMapC Sin
    cos   = vectorMapC Cos
    tan   = vectorMapC Tan
    asin  = vectorMapC ASin
    acos  = vectorMapC ACos
    atan  = vectorMapC ATan
    sinh  = vectorMapC Sinh
    cosh  = vectorMapC Cosh
    tanh  = vectorMapC Tanh
    asinh = vectorMapC ASinh
    acosh = vectorMapC ACosh
    atanh = vectorMapC ATanh
    exp   = vectorMapC Exp
    log   = vectorMapC Log
    sqrt  = vectorMapC Sqrt
    (**)  = adaptScalar (vectorMapValC PowSV) (vectorZipC Pow) (flip (vectorMapValC PowVS))
    pi    = fromList [pi]

-----------------------------------------------------------

instance Floating (Vector (Complex Float)) where
    sin   = vectorMapQ Sin
    cos   = vectorMapQ Cos
    tan   = vectorMapQ Tan
    asin  = vectorMapQ ASin
    acos  = vectorMapQ ACos
    atan  = vectorMapQ ATan
    sinh  = vectorMapQ Sinh
    cosh  = vectorMapQ Cosh
    tanh  = vectorMapQ Tanh
    asinh = vectorMapQ ASinh
    acosh = vectorMapQ ACosh
    atanh = vectorMapQ ATanh
    exp   = vectorMapQ Exp
    log   = vectorMapQ Log
    sqrt  = vectorMapQ Sqrt
    (**)  = adaptScalar (vectorMapValQ PowSV) (vectorZipQ Pow) (flip (vectorMapValQ PowVS))
    pi    = fromList [pi]

-----------------------------------------------------------


-- instance (Storable a, Num (Vector a)) => Monoid (Vector a) where
--     mempty = 0 { idim = 0 }
--     mappend a b = mconcat [a,b]
--     mconcat = j . filter ((>0).dim)
--         where j [] = mempty
--               j l  = join l

---------------------------------------------------------------

-- instance (NFData a, Storable a) => NFData (Vector a) where
--     rnf = rnf . (@>0)
--
-- instance (NFData a, Element a) => NFData (Matrix a) where
--     rnf = rnf . flatten


--------------------------------------------------------------------------
