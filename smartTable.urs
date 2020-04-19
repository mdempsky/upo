(* A configurable way of listing table rows as HTML tables *)

con t :: {Type} (* available columns of table we are listing *)
    -> Type     (* configuration, to prepare once on server *)
    -> Type     (* internal type for server-generated data to render locally *)
    -> Type

val compose : r ::: {Type} -> cfga ::: Type -> cfgb ::: Type
              -> sta ::: Type -> stb ::: Type
              -> t r cfga sta -> t r cfgb stb -> t r (cfga * cfgb) (sta * stb)

con column_cfg :: Type -> Type
con column_st :: Type -> Type
val column : col :: Name -> colT ::: Type -> r ::: {Type} -> [[col] ~ r]
             => show colT
             -> string (* label *)
             -> t ([col = colT] ++ r) (column_cfg colT) (column_st colT)

type html_cfg
type html_st
val html : col :: Name -> r ::: {Type} -> [[col] ~ r]
           => string (* label *)
           -> t ([col = string] ++ r) html_cfg html_st

con iconButton_cfg :: {Type} -> Type
con iconButton_st :: {Type} -> Type
val iconButton : cols ::: {Type} -> r ::: {Type} -> [cols ~ r]
                 => transaction (option string) (* get username, if any *)
                 -> (option string (* username, if any *)
                     -> time       (* very recent timestamp *)
                     -> $cols      (* values of selected columns *)
                     -> option (css_class (* choose a Font Awesome icon *)
                                * url     (* ...and where clicking should take you *)))
                 -> string (* label *)
                 -> t (cols ++ r) (iconButton_cfg cols) (iconButton_st cols)

con linked_cfg :: Type -> Type
con linked_st :: Type -> Type
val linked : this :: Name -> fthis :: Name -> thisT ::: Type
             -> fthat :: Name -> thatT ::: Type
             -> r ::: {Type} -> fr ::: {Type} -> ks ::: {{Unit}}
             -> [[this] ~ r] => [[fthis] ~ [fthat]] => [[fthis, fthat] ~ fr]
             => show thatT -> sql_injectable thisT
             -> sql_table ([fthis = thisT, fthat = thatT] ++ fr) ks
             -> string (* label *)
             -> t ([this = thisT] ++ r) (linked_cfg thatT) (linked_st thatT)

con orderedLinked_cfg :: Type -> Type
con orderedLinked_st :: Type -> Type
val orderedLinked : this :: Name -> fthis :: Name -> thisT ::: Type
                    -> fthat :: Name -> thatT ::: Type
                    -> r ::: {Type} -> fr ::: {Type} -> ks ::: {{Unit}}
                    -> [[this] ~ r] => [[fthis] ~ [fthat]] => [[fthis, fthat] ~ [SeqNum]] => [[fthis, fthat, SeqNum] ~ fr]
                    => show thatT -> sql_injectable thisT
                    -> sql_table ([fthis = thisT, fthat = thatT, SeqNum = int] ++ fr) ks
                    -> string (* label *)
                    -> t ([this = thisT] ++ r) (orderedLinked_cfg thatT) (orderedLinked_st thatT)

functor LinkedWithFollow(M : sig
                             con this :: Name
                             con fthis :: Name
                             con thisT :: Type
                             con fthat :: Name
                             con thatT :: Type
                             con r :: {Type}
                             constraint [this] ~ r
                             constraint [fthis] ~ [fthat]
                             val show_that : show thatT
                             val inj_this : sql_injectable thisT
                             val inj_that : sql_injectable thatT
                             table from : {fthis : thisT, fthat : thatT}

                             con user :: Name
                             con cthat :: Name
                             constraint [user] ~ [cthat]
                             table to : {user : string, cthat : thatT}

                             val label : string
                             val whoami : transaction (option string)
                         end) : sig
    type cfg
    type internal
    val t : t ([M.this = M.thisT] ++ M.r) cfg internal
end

(* Indicate interest in the current item. *)
functor Like(M : sig
                 con this :: Name
                 con fthis :: Name
                 con thisT :: Type
                 con user :: Name
                 con r :: {Type}
                 constraint [this] ~ r
                 constraint [fthis] ~ [user]
                 val inj_this : sql_injectable thisT
                 table like : {fthis : thisT, user : string}

                 val label : string
                 val whoami : transaction (option string)
             end) : sig
    type cfg
    type internal
    val t : t ([M.this = M.thisT] ++ M.r) cfg internal
end

(* Like [Like], but with an additional option to indicate preferred choices *)
functor Bid(M : sig
                con this :: Name
                con fthis :: Name
                con thisT :: Type
                con user :: Name
                con preferred :: Name
                con r :: {Type}
                constraint [this] ~ r
                constraint [fthis] ~ [user]
                constraint [fthis, user] ~ [preferred]
                val inj_this : sql_injectable thisT
                table bid : {fthis : thisT, user : string, preferred : bool}

                val label : string
                val whoami : transaction (option string)
            end) : sig
    type cfg
    type internal
    val t : t ([M.this = M.thisT] ++ M.r) cfg internal
end

(* Now an admin can use those bids to assign users to items. *)
functor AssignFromBids(M : sig
                           con this :: Name
                           con assignee :: Name
                           con fthis :: Name
                           con thisT :: Type
                           con user :: Name
                           con preferred :: Name
                           con r :: {Type}
                           constraint [this] ~ [assignee]
                           constraint [this, assignee] ~ r
                           constraint [fthis] ~ [user]
                           constraint [fthis, user] ~ [preferred]
                           val inj_this : sql_injectable thisT
                           table bid : {fthis : thisT, user : string, preferred : bool}

                           val label : string
                           val whoami : transaction (option string)

                           table tab : ([this = thisT, assignee = option string] ++ r)
                       end) : sig
    type cfg
    type internal
    val t : t ([M.this = M.thisT, M.assignee = option string] ++ M.r) cfg internal
end

type nonnull_cfg
type nonnull_st
val nonnull : col :: Name -> ct ::: Type -> r ::: {Type} -> [[col] ~ r]
              => t ([col = option ct] ++ r) nonnull_cfg nonnull_st

type taggedWithUser_cfg
type taggedWithUser_st
val taggedWithUser : user :: Name -> r ::: {Type} -> [[user] ~ r]
                   => transaction (option string) (* get username, if any *)
                   -> t ([user = string] ++ r) taggedWithUser_cfg taggedWithUser_st

type linkedToUser_cfg
type linkedToUser_st
val linkedToUser : key :: Name -> keyT ::: Type -> r ::: {Type} -> [[key] ~ r]
                   => ckey :: Name -> user :: Name -> cr ::: {Type} -> ks ::: {{Unit}} -> [[ckey] ~ [user]] => [[ckey, user] ~ cr]
                   => sql_table ([ckey = keyT, user = string] ++ cr) ks (* connector that must link current user to row *)
                   -> transaction (option string) (* get username, if any *)
                   -> t ([key = keyT] ++ r) linkedToUser_cfg linkedToUser_st

type doubleLinkedToUser_cfg
type doubleLinkedToUser_st
val doubleLinkedToUser : key :: Name -> keyT ::: Type -> r ::: {Type} -> [[key] ~ r]
                         => ckey :: Name -> ikey :: Name -> ikeyT ::: Type -> cr1 ::: {Type} -> ks1 ::: {{Unit}} -> [[ckey] ~ [ikey]] => [[ckey, ikey] ~ cr1]
                         => ikey2 :: Name -> user :: Name -> cr2 ::: {Type} -> ks2 ::: {{Unit}} -> [[ikey2] ~ [user]] => [[ikey2, user] ~ cr2]
                         => sql_table ([ckey = keyT, ikey = ikeyT] ++ cr1) ks1
                         -> sql_table ([ikey2 = ikeyT, user = string] ++ cr2) ks2
                         -> transaction (option string) (* get username, if any *)
                         -> t ([key = keyT] ++ r) doubleLinkedToUser_cfg doubleLinkedToUser_st

type sortby_cfg
type sortby_st
val sortby : col :: Name -> ct ::: Type -> r ::: {Type} -> [[col] ~ r]
             => t ([col = ct] ++ r) sortby_cfg sortby_st
                       
functor Make(M : sig
                 con r :: {(Type * Type * Type)}
                 table tab : (map fst3 r)

                 type cfg
                 type st
                 val t : t (map fst3 r) cfg st
                 val widgets : $(map Widget.t' r)
                 val fl : folder r
                 val labels : $(map (fn _ => string) r)
                 val injs : $(map (fn p => sql_injectable p.1) r)

                 val authorized : transaction bool
                 val allowCreate : bool
             end) : Ui.S0
