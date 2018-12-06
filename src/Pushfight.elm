--import Browser
import Debug
import Dict exposing (Dict)
import Set exposing (Set)
--import Html
--import Html.Attributes
--import Html.Events exposing (on)
--import Html.Events.Extra.Mouse as Mouse
--import Json.Decode as Decode


import Browser
import Browser.Events
import Html
import Html.Events
import Html.Events.Extra.Mouse as Mouse
import Svg
import Svg.Attributes
import Json.Decode as Decode

import Draw




main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


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
    }

type alias Position =
    { x : Int
    , y : Int
    }
    
type alias PositionKey = (Int, Int)

type alias Board =
    Dict PositionKey Piece


type alias Model =
    { board : Board
    , lastMovedPiece : Maybe MovingPiece
    , dragState : Maybe Position -- has to be separate to handle timing issues
    , anchor : Maybe Position
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        startingPieces =
            [ ( (3, 2), Piece Mover  White )
            , ( (4, 0), Piece Pusher White )
            , ( (4, 1), Piece Mover  White )
            , ( (4, 2), Piece Pusher White )
            , ( (4, 3), Piece Pusher White )
            , ( (5, 0), Piece Pusher Black )
            , ( (5, 1), Piece Mover  Black )
            , ( (5, 2), Piece Pusher Black )
            , ( (5, 3), Piece Pusher Black )
            , ( (6, 2), Piece Mover  Black )
            ] |> Dict.fromList
    in
        ( Model startingPieces Nothing Nothing Nothing
        , Cmd.none
        )



-- UPDATE


type Msg
    = DragStart Position
    | DragAt Position
    | DragEnd Position
    | MouseDownAt (Float, Float)



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragStart pos ->
            ( { model | dragState = Just pos}
            , Cmd.none
            )

        DragAt pos ->
            ( { model | dragState = Just pos}
            , Cmd.none
            )

        DragEnd pos ->
            ( handleDragEnd { model | dragState = Just pos }
            , Cmd.none
            )
        MouseDownAt (x, y) ->
            ( handleClick model (fromPxToGrid x, fromPxToGrid y)
            , Cmd.none
            )

popPiece : PositionKey -> Board -> (Board, Maybe Piece)
popPiece key board = 
    case Dict.get key board of
        Just piece ->
            (Dict.remove key board, Just piece)
        Nothing ->
            (board, Nothing)

handleClick : Model -> PositionKey -> Model
handleClick model (x, y) =
    let
        (newBoard, maybePiece) = popPiece (x, y) model.board
        movingPiece = case
            maybePiece of
                Just piece ->
                     Just <| MovingPiece piece (Position x y)
                Nothing ->
                    Nothing

        updatedModel = { model | board = newBoard, lastMovedPiece = movingPiece}
    in
        Debug.log ("handleClick " ++ (Debug.toString updatedModel.lastMovedPiece)) updatedModel

handleDragEnd : Model -> Model
handleDragEnd model =
    model

--isConnected : Position -> Position -> Bool
--isConnected pos1 pos2 =
--    abs(pos1.x - pos2.x) + (pos1.y - pos2.y) /= 1

isPositionInBoard : (Int, Int) -> Bool
isPositionInBoard (x, y) = 
    Draw.isInBoard x y

getNeighbors : PositionKey -> Set PositionKey
getNeighbors (x, y) = 
    List.filter
        isPositionInBoard
        [ ((x + 1),  y     )
        , ((x - 1),  y     )
        , ( x     , (y + 1))
        , ( x     , (y - 1))
        ]
    |> Set.fromList


breadthFirstSearchImpl : List PositionKey -> Set PositionKey -> List PositionKey -> Set PositionKey
breadthFirstSearchImpl unexplored occupied explored =
    case unexplored of
        [] ->
            Set.fromList explored
        x :: xs ->
            let
                neighbors = getNeighbors x
                unexploredNeighbors = Set.diff occupied <| Set.diff neighbors (Set.fromList explored)
                toExplore = unexploredNeighbors
                    |> Set.toList
                    |> List.append xs
            in
                breadthFirstSearchImpl toExplore occupied (x :: explored)


breadthFirstSearch : PositionKey -> Set PositionKey -> Set PositionKey
breadthFirstSearch start occupied =
    breadthFirstSearchImpl [start] occupied []

isValidMove : Board -> PositionKey -> PositionKey -> Bool
isValidMove board from to =
    if Dict.member to board then
        False
    else if not (Dict.member from board) then
        False
    else
        let
            occupied = Set.fromList <| Dict.keys board
            validMoves = breadthFirstSearch from occupied
        in
            Set.member to validMoves

getPushedPieces : Board -> PositionKey -> PositionKey -> List PositionKey -> List PositionKey
getPushedPieces board from to pushed =
    let
        (toX, toY) = to
        (fromX, fromY) = from
        dx = toX - fromX
        dy = toY - fromY
        next = (toX + dx, toY + dy)
        havePushed = to :: pushed
    in
        if Dict.member to board then
            getPushedPieces board to next havePushed
        else
            pushed

move : Board -> (Int, Int) -> (Int, Int) -> Maybe Board
move board from to =
    case Dict.get from board of
        Just piece ->
            if isValidMove board from to then
                Dict.insert to piece board
                |> Dict.remove from
                |> Just

            else
                Nothing
        Nothing ->
            Nothing



position : Decode.Decoder Position
position =
    Decode.map2 Position
        (Decode.field "pageX" Decode.int)
        (Decode.field "pageY" Decode.int)

subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragState of
        Nothing ->
            Browser.Events.onMouseDown (Decode.map DragStart position)

        _ ->
            Sub.batch
                [ Browser.Events.onMouseMove (Decode.map DragAt position)
                , Browser.Events.onMouseUp (Decode.map DragEnd position)
                ]

drawPiece : Int -> (PositionKey, Piece) -> List (Svg.Svg Msg)
drawPiece size ( (x, y), {kind, color} ) =
    let
        colorString =
            case color of
                White ->
                    "#ffffff"
                Black ->
                    "#000000"
    in
        case kind of
            Pusher ->
                Draw.pusher size x y colorString
            Mover ->
                Draw.mover size x y colorString

grid_size = 200

fromPxToGrid : Float -> Int
fromPxToGrid x =
    (floor x)//grid_size


view : Model -> Html.Html Msg
view model =
    let
        size = grid_size
        totalSize = String.fromInt (10*size)
        anchor =
            case model.anchor of
                Just {x, y} ->
                    Draw.anchor size x y
                Nothing ->
                    []
        movingPiece =
            case (model.lastMovedPiece, model.dragState) of
                (Just {piece}, Just {x, y}) ->
                    drawPiece size ((x//grid_size, y//grid_size), piece)
                (Just {piece, from}, Nothing) ->
                    drawPiece size ((from.y, from.x), piece)
                _ ->
                    []
    in
    Html.div [Mouse.onDown (\event -> MouseDownAt event.offsetPos)]
    [ Svg.svg 
        [ Svg.Attributes.width totalSize
        , Svg.Attributes.height totalSize
        , Svg.Attributes.viewBox <| "0 0 " ++ totalSize ++ " " ++ totalSize
        ]
        ( List.concat
            [ Draw.board size
            , List.concat (List.map (drawPiece size) <| Dict.toList model.board)
            , anchor
            , movingPiece
            ]
        )
    ]
