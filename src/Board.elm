module Board exposing (init, update, view, Msg, Model)

import Debug exposing (log, toString)

import Dict exposing (Dict)

import Html
import Html.Events
import Html.Attributes
import Html.Events.Extra.Mouse as Mouse

import Svg exposing (..)
import Svg.Attributes exposing (..)

import Router



type alias Board = Dict String Bool


type alias Model =
    { board : Board
    , nrows : Int
    , ncols : Int
    , npixels : Int
    , gameID : String
    }


init : String -> ( Model, Cmd Msg , Maybe Router.Msg )
init gameID =
    ( Model Dict.empty 10 10 50 gameID
    , Cmd.none
    , Nothing
    )


type Msg
    = MouseDownAt ( Float, Float )
    | GoToLobby


togglePieceImpl : Maybe Bool -> Maybe Bool
togglePieceImpl val = 
    case val of
        Just _ -> Nothing
        Nothing -> Just True


togglePiece : Board -> String -> Board
togglePiece d k =
    d |> Dict.update k togglePieceImpl


update : Msg -> Model -> ( Model, Cmd Msg, Maybe Router.Msg )
update msg model =
    case msg of
        MouseDownAt (x, y) ->
            let
                row = (floor y) // model.npixels
                col = (floor x) // model.npixels
            in
                if col < model.ncols && row < model.nrows then
                    let
                        updatedBoard = togglePiece model.board (String.fromInt (row * model.ncols + col ))
                    in
                        ( { model | board =  updatedBoard}
                        , Cmd.none
                        , Nothing
                        )
                else
                    ( model
                    , Cmd.none
                    , Nothing
                    )

        GoToLobby ->
            ( model
            , Cmd.none
            , Just Router.GoToLobby
            )


drawBoardSquares : Int -> Int -> Int -> Board -> Int -> List (Svg Msg) -> List (Svg Msg)
drawBoardSquares nrows ncols npixels board key squares =
    let
        px = (npixels * (modBy ncols key) + npixels // 2)
        py = (npixels * (key // ncols   ) + npixels // 2)
    in
        if key >= (nrows * ncols) then
            squares
        else
            case Dict.get (String.fromInt key) board of
                Just piece ->
                    drawBoardSquares nrows ncols npixels board (key + 1) (List.append squares [drawCircle px py (npixels//2) "black"])
                Nothing ->
                    drawBoardSquares nrows ncols npixels board (key + 1) (List.append squares [drawCircle px py (npixels//2) "white"])


drawCircle : Int -> Int -> Int -> String -> Svg Msg
drawCircle x y radius color =
    circle [ cx (String.fromInt x), cy (String.fromInt y), r (String.fromInt radius), fill color] []


view : Model -> Html.Html Msg
view model =
    let
        pxwidth  = String.fromInt (model.ncols * model.npixels)
        pxheight = String.fromInt (model.nrows * model.npixels)
    in
        Html.div []
        [ Html.div [Mouse.onDown (\event -> MouseDownAt event.offsetPos)]
            [svg
                [ width pxwidth, height pxwidth, viewBox ("0 0" ++ " " ++ pxwidth ++ " " ++ pxheight), fill "gray", stroke "black", strokeWidth "0 "]
                (drawBoardSquares model.nrows model.ncols model.npixels model.board 0 [ rect [ x "0", y "0", width pxwidth, height pxheight] [] ])
            ]
        , Html.div [] [Html.button [ Html.Events.onClick GoToLobby ] [ Html.text "Lobby" ]]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
