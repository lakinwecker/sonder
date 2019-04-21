import chess.pgn

def pgn_to_uci(pgn):
    """A method that should take a PGN string and return a list of uci moves.
    """
    pgn = io.StringIO(pgn)
    game = chess.pgn.read_game(pgn)
    moves = []
    for move in game.mainline_moves():
        moves.append(move.uci())
    return moves
