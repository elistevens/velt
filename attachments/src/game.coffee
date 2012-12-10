$db = $.couch.db("velt");

$changes = $.couch.db("mydatabase").changes()
$changes.onChange = (data) ->
    if data.type == "card_move"
        card_dict[data.card_id].finishMove(data)


$db.changes.onChange(onChange_func, {"include_docs": true})

location_dict = {}
class Location
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

    render: (isThisPlayer) ->
        s = """
            <div class="#{@style} location">
                <div class="location_name">#{@name}</div>
        """ #"

        if @card_list.length == 0
            s += """(Empty)"""
        else
            s += @card_list[0].render(isThisPlayer)

        s += """<div class="location_count">Count: #{@card_list.length}</div></div>"""

        return s

face_dict = {}
card_dict = {}
class Card
    constructor: (doc) ->
        # doc: name, text, style
        @style = "grey"
        @nextLocationOverride_dict = {}
        @nextPositionOverride_dict = {}

        for attr of doc
            this[attr] = doc[attr]

        if @faceUp of face_dict
            @faceUp = face_dict[@faceUp]
        if @faceDown of face_dict
            @faceDown = face_dict[@faceDown]

        card_dict[@_id] = this

    nextLocation: (nextLocation_str) ->
        return nextLocation_str or @nextLocationOverride_dict[@location_str] or location_dict[@location_str].nextLocation_str

    nextPosition: (nextLocation_str, nextPosition_str) ->
        nextPosition_str = nextPosition_str or @nextPositionOverride_dict[nextLocation_str] or location_dict[nextLocation_str].nextPosition_str

        new_loc = location_dict[nextLocation_str]
        card_list = new_loc.card_list

        if card_list.length == 0
            position = 0
        elif nextPosition_str == "top"
            position = card_list[card_list.length - 1].position + 1
        elif nextPosition_str == "bottom"
            position = card_list[0].position - 1

        return position

    startMove: (nextLocation_str, nextPosition_str) ->
        nextLocation_str = @nextLocation(nextLocation_str)
        if nextLocation_str is null
            alert "No default next location set"
            return

        position = @nextPosition(nextLocation_str, nextPosition_str)

        now = new Date()
        new_loc = location_dict[nextLocation_str]
        card_list = new_loc.card_list

        $db.saveDoc({"type": "card_move", "card_id": @_id, "location": nextLocation_str, "position": position, "player": player, "time": now.getTime()})

    finishMove: (doc) ->
        current_loc = location_dict[@location_str]

        if current_loc
            current_loc.card_list = [card for card in current_loc.card_list if card._id != @_id]

        @location_str = doc.location

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
