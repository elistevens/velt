$db = $.couch.db("velt");

#{
#    results: [
#        {
#            seq: 4,
#            id: "_design/tmp",
#            changes: [
#                {
#                    rev: "2-4c2dea92ed3c1d56b40a52b87da50f2a"
#                }
#            ],
#            deleted: true,
#            doc: {
#                _id: "_design/tmp",
#                _rev: "2-4c2dea92ed3c1d56b40a52b87da50f2a",
#                _deleted: true
#            }
#        },
#        ...
#    ]
#}
$changes = $.couch.db("mydatabase").changes({"include_docs": true})
$changes.onChange = (data) ->
    for result in data.results
        if not result.deleted
            doc = result.doc
            if doc.type in ["card_move", "card_shuffle"]
                card_dict[doc.card_id].finishMove(doc)

$db.changes.onChange(onChange_func)

location_dict = {}
class DeckLocation
    # Locations are places in the game like "the draw deck" or "discard."
    # They have a list of cards currently in that location, each ordered by the
    # card's "position" attribute.
    constructor: (doc) ->
        @card_list = []
        @face_str = "faceDown"
        @nextPosition_str = "top"

        for attr of doc
            this[attr] = doc[attr]

        location_dict[@_id] = this

    shuffleTo: (card_list, shuffleLocation_str) ->
        shuffleLocation_str = shuffleLocation_str or @shuffleLocation_str
        shuffle_loc = location_dict[shuffleLocation_str]
        position_offset = shuffle_loc.card_list[shuffle_loc.card_list.length - 1].position + 1

        for card, i in @card_list
            j = Math.floor(Math.random() * @card_list.length)
            @card_list[i], @card_list[j] = @card_list[j], @card_list[i]

        for card, i in @card_list
            card.position = position_offset + i
            $db.saveDoc({"type": "card_shuffle", "card_id": card._id, "location": shuffleLocation_str, "position": position, "player": player, "time": now.getTime()})

        @card_list = []

    render: (isThisPlayer) ->
        s = """
            <div class="#{@style} location">
                <div class="location_name">#{@name} (#{@card_list.length})</div>
        """ #"

        if @card_list.length == 0
            s += """(Empty)"""
        else
            s += @card_list[0].render(isThisPlayer)

        #s += """<div class="location_count">Count: #{@card_list.length}</div>"""
        s += """</div>"""

        return s

face_dict = {}
card_dict = {}
class Card
    constructor: (doc) ->
        # doc: name, text, style
        @style = "grey"
        @moveLocationOverride_dict = {} # current location : next location
        @movePositionOverride_dict = {}

        for attr of doc
            this[attr] = doc[attr]

        if @faceUp of face_dict
            @faceUp = face_dict[@faceUp]
        if @faceDown of face_dict
            @faceDown = face_dict[@faceDown]

        card_dict[@_id] = this

    moveLocation: (moveLocation_str) ->
        return moveLocation_str or @moveLocationOverride_dict[@location_str] or location_dict[@location_str].moveLocation_str

    movePosition: (moveLocation_str, movePosition_str) ->
        movePosition_str = movePosition_str or @movePositionOverride_dict[moveLocation_str] or location_dict[moveLocation_str].movePosition_str

        new_loc = location_dict[moveLocation_str]
        card_list = new_loc.card_list

        if card_list.length == 0
            position = 0
        elif movePosition_str == "top"
            position = card_list[card_list.length - 1].position + 1
        elif movePosition_str == "bottom"
            position = card_list[0].position - 1

        return position

    startMove: (moveLocation_str, movePosition_str) ->
        moveLocation_str = @moveLocation(moveLocation_str)
        if moveLocation_str is null
            alert "No default move location set"
            return

        position = @movePosition(moveLocation_str, movePosition_str)

        now = new Date()
        new_loc = location_dict[moveLocation_str]
        card_list = new_loc.card_list

        $db.saveDoc({"type": "card_move", "card_id": @_id, "location": moveLocation_str, "position": position, "player": player, "time": now.getTime()})

    finishMove: (doc) ->
        current_loc = location_dict[@location_str]

        if current_loc
            current_loc.card_list = [card for card in current_loc.card_list if card._id != @_id]

        @location_str = doc.location
        @position = doc.position

        new_loc = location_dict[@location_str]
        card_list = new_loc.card_list
        card_list[card_list.length] = card
        card_list.sort((a, b) -> a.position - b.position)

    render: (isThisPlayer, face_str) ->
        current_loc = location_dict[@location_str]
        face_str = face_str or current_loc.face_str
        if face_str == "facePrivate":
            face_str = "faceUp" if isThisPlayer else "faceDown"

        face = this[face_str]

        return """
            <div class="#{face.style} card">
                <div class="card_name">#{face.name}</div>
                <div class="card_text">#{face.text}</div>
            </div>""" #"




# eof
