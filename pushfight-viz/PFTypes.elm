module PFTypes exposing (..)

import Dict exposing (Dict)

type PieceKind
    = Pusher
    | Mover


type PieceColor
    = Black
    | White


type Direction
    = Up
    | Left
    | Right
    | Down

type alias Piece =
    { kind : PieceKind
    , color : PieceColor
    }

type alias MovingPiece =
    { piece : Piece
    , from : Position
    , mouseDrag : Maybe MouseDrag
    }

type alias Position =
    { x : Int
    , y : Int
    }
    
type alias PositionKey = (Int, Int)

type alias Pieces = Dict PositionKey Piece

type alias Board =
    { pieces: Pieces
    , anchor: Maybe Position
    }

type alias MouseDrag =
    { dragStart   : Position
    , dragCurrent : Position
    }

type alias Move =
    { from : PositionKey
    , to : PositionKey
    }

type GameStage
    = WhiteSetup
    | BlackSetup
    | WhiteTurn
    | BlackTurn
    | WhiteWon
    | BlackWon

type alias Turn =
    { moves : List Move
    , push  : Maybe Move
    , startingBoard : Board
    }

type DragState
    = NotDragging
    | DraggingNothing MouseDrag
    | DraggingPiece MovingPiece
