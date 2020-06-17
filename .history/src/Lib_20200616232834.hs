module Lib where

import System.IO
import Data.List
import qualified System.Process as SP
import Control.Monad
    
data Game = Game {
    wordPlay:: String,
    wordReady:: String,
    maxTryTimes :: Int,
    tryTime:: Int,
    tryLetters :: String
} deriving (Show, Eq)
game :: String -> Game
game word = Game word replaceByUnderscore 3 0 "" where
    replaceByUnderscore = intercalate "" (map (\_-> "_") word)

data Result = GameWin | GameLoose | KeepAsking | LetterAlreadyExist deriving (Show, Eq)
data ActionResult = IsLetterInTryLetters | IsLetterInWordReady | AlreadyUseThisLetter
step :: Game -> Char -> (Game , Result)
step state input = 
    let rightGame = rightWay state input
        isWordUsing = isCharUsingByWords state input
    in if isWordUsing
        then 
            (state , LetterAlreadyExist)
        else 
            let (endGame, winGame) = checkEnd rightGame
            in if winGame || endGame
                then
                    if winGame
                     then (rightGame , GameWin)
                     else (rightGame , GameLoose)
                else (rightGame , KeepAsking)


isCharUsingByWords :: Game -> Char -> Bool
isCharUsingByWords state input = 
    let isLetterInTryLetters = any (==input) (tryLetters state)
        isLetterInWordReady = any (==input) (wordReady state)
    in
        if (isLetterInTryLetters || isLetterInWordReady)
            then
                True
            else False
            
play :: String -> IO ()
play word = welcome (game word) >>= go where
-- play2 word = (go <=< welcome) (game word) where
    welcome:: Game -> IO Game
    welcome state = do
        _ <- clearScreen
        putStrLn "Bienvenido al Ahorcado 4"
        showGame state
        putStrLn "-------------------"
        return state
    go :: Game -> IO ()
    go state = do
        putStr "Ingrese una letra : "
        letter <- getChar   
        case step state letter of 
            (_, GameWin) -> putStrLn "Ganaste"
            (_, GameLoose) -> putStrLn "Perdiste"
            (state', _) -> welcome state' >>= go
        return ()


type WinGame = Bool
type EndGame = Bool
checkEnd :: Game -> (EndGame, WinGame)
checkEnd game =
    let winGame = notElem '_' (wordReady game)
        endGame = winGame || tryTime game > maxTryTimes game
    in (endGame, winGame)

rightWay :: Game -> Char -> Game
rightWay state letter =
    let right = any (==letter) (wordPlay state)
        nextTryTime = (tryTime state) + 1
        newWordReady = zipWith (\c v -> if c == letter
                                            then
                                                [c]
                                            else
                                                if v == '_'
                                                    then "_"
                                                    else [v]) (wordPlay state) (wordReady state)
    in if right 
            then state { wordReady = concat newWordReady, tryLetters = (tryLetters state ++ [letter]) }
            else state { tryLetters = (tryLetters state ++ [letter]) , tryTime = nextTryTime}


showGame :: Game -> IO()
showGame state = do
    putStrLn $ "Cantidad de intento totales : " ++ show  (maxTryTimes state)
    putStrLn $ "Cantidad de intento ejecutados : " ++ (show $ tryTime state)
    putStrLn $ "Palabra a adivinar : " ++  intersperse ' ' (wordReady state)
    putStrLn $ "Letras ya usadas : " ++ intersperse '-' (tryLetters state)

clearScreen :: IO ()
clearScreen = do
    _ <- SP.system "reset"
    return ()
