import chess.pgn
import io

def pgn_to_uci(pgn):
    """A method that should take a PGN string and return a list of uci moves.
    """
    pgn = io.StringIO(pgn)
    game = chess.pgn.read_game(pgn)
    moves = []
    for move in game.mainline_moves():
        moves.append(move.uci())
    return moves

def import_pgn_to_db(pgn, encoding="ISO-8859-1"):
    pgn_in = open(pgn, encoding=encoding)
    game = chess.pgn.read_game(pgn_in)
    while game:
        insert_game_into_db(game)
        game = chess.pgn.read_game(pgn_in)

def insert_game_into_db(game):
    w, _ = Player.objects.get_or_create(username=game.headers['White'])
    b, _ = Player.objects.get_or_create(username=game.headers['Black'])
    exporter = chess.pgn.StringExporter(headers=True, variations=False, comments=False)
    pgn_text = game.accept(exporter)
    lichess_id = game.headers['Site'][-8:]
    g, _ = Game.objects.get_or_create(
        lichess_id=lichess_id,
        defaults={
            'white_player': w,
            'black_player': b,
            'time_control': game.headers['TimeControl']
        }
    )
    g.set_pgn(pgn_text)
    g.save()
