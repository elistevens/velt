var couchapp = require('couchapp');
var path = require('path');

ddoc = {
    _id:'_design/data'
};

ddoc.language = 'coffeescript';
ddoc.views = couchapp.loadFiles('./views');

module.exports = ddoc;
