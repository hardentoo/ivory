{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

module Ivory.Stdlib.Control
  ( ifte
  , when
  , unless
  , cond_, (==>)
  ) where

import Ivory.Language

ifte :: (IvoryStore a, IvoryZero (Stored a), WithAllocs eff ~ eff)
     => IBool
     -> Ivory (Effects eff) a
     -> Ivory (Effects eff) a
     -> Ivory (Effects eff) a
ifte c t f = do
  r <- local izero
  ifte_ c
    (t >>= (store r))
    (f >>= (store r))
  deref r

when :: IBool -> Ivory eff () -> Ivory eff ()
when c t = ifte_ c t (return ())

unless :: IBool -> Ivory eff () -> Ivory eff ()
unless c f =  ifte_ c (return ()) f

data Cond eff = Cond IBool (Ivory eff ())

(==>) :: IBool -> Ivory eff () -> Cond eff
(==>) = Cond

infix 0 ==>

-- | A multi-way if.  This is useful for avoiding an explosion of
-- nesting and parentheses in complex conditionals.
--
-- Instead of writing nested chains of ifs:
--
-- > ifte_ (x >? 100)
-- >   (store result 10)
-- >   (ifte_ (x >? 50)
-- >     (store result 5)
-- >     (ifte_ (x >? 0)
-- >       (store result 1)
-- >       (store result 0)))
--
-- You can write:
--
-- > cond_
-- >   [ x >? 100 ==> store result 10
-- >   , x >? 50  ==> store result 5
-- >   , x >? 0   ==> store result 1
-- >   , true     ==> store result 0
-- >   ]
--
-- Note that "==>" is non-associative and has precedence 0, so you
-- will need parentheses to call functions with "$" on the left-hand
-- side:
--
-- > cond_ [ (f $ g x) ==> y ]
--
-- rather than:
--
-- > cond_ [ f $ g x ==> y ]
cond_ :: [Cond eff] -> Ivory eff ()
cond_ [] = return ()
cond_ ((Cond b f):cs) = ifte_ b f (cond_ cs)
