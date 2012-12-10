(doc) ->
    if doc.type == "card_move"
        emit [doc.card_id, doc.time], [doc.location, doc.position, doc.time]
