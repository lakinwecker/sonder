import chess.pgn
import io

from .analysis.models import Player, Game

class GamePlayerConflict(AssertionError):
    pass

def pgn_to_uci(pgn):
    """A method that should take a PGN string and return a list of uci moves.
    """
    pgn = io.StringIO(pgn)
    game = chess.pgn.read_game(pgn)
    moves = []
    for move in game.mainline_moves():
        moves.append(move.uci())
    return moves

def import_pgn_file_to_db(pgn_file, encoding="ISO-8859-1"):
    pgn_in = open(pgn_file, encoding=encoding)
    return import_pgn_to_db(pgn_in)

def import_pgn_to_db(pgn_in):
    game = chess.pgn.read_game(pgn_in)
    while game:
        insert_game_into_db(game)
        game = chess.pgn.read_game(pgn_in)

def insert_game_into_db(game):
    white_username = Player.normalize_username(game.headers['White'])
    black_username = Player.normalize_username(game.headers['Black'])
    w, _ = Player.objects.get_or_create(username=white_username)
    b, _ = Player.objects.get_or_create(username=black_username)
    exporter = chess.pgn.StringExporter(headers=True, variations=False, comments=False)
    pgn_text = game.accept(exporter)
    lichess_id = game.headers['Site'][-8:]
    g, _ = Game.objects.get_or_create(
        lichess_id=lichess_id,
    )
    if g.white_player and g.white_player != w:
        raise GamePlayerConflict(
            f"PGN expects game to have {w} as white, but db has {g.white_player} as white."
        )
    if g.black_player and g.black_player != b:
        raise GamePlayerConflict(
            f"PGN expects game to have {b} as black, but db has {g.black_player} as black."
        )
    g.white_player = w
    g.black_player = w
    g.time_control = game.headers['TimeControl']
    g.set_pgn(pgn_text)
    g.save()
