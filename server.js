'use strict';

var Promise = require('bluebird');
var mt = require('microtools');
<<<<<<< HEAD
=======
var fs = require('fs');

const WORKSPACE_LOC = 'workspace';
const KEYS_KEY = 'keys';
const UPDATE_ACTION = 'update';
const USERNAME_KEY = 'ownerId';
const EMAIL_KEY = 'email';
const UPDATE_SSH_ACTION = 'update_ssh';
const UPDATE_EMAIL_ACTION = 'update_email';
const AUTH_KEYS_ROOT = '/root/.ssh/'
const AUTH_KEYS_PATH = '/root/.ssh/authorized_keys';
>>>>>>> b172a2d9535c5ed7796e5e98c057867e99b1a768

var webcommit = {
    name: process.env.webcommit_NAME || 'webcommit',
    categories: [mt.TOOLS_CAT_VALIDATORS],
    topics: [mt.NIKKA_CAT_FS],
    rootDir: __dirname,

    notify: function(note) {
        if (note.topics.indexOf(mt.NIKKA_CAT_FS) >= 0) {
            mt.log.info({topics: note.topics}, 'Notified for changes. Running again.');
            mt.run()
        }
    },

    run: function() {
        return new Promise(function(resolve, reject) {
            resolve({
                statusCode: mt.SC_FINISHED_SUCCESSFULLY,
                results: {
                    message: 'webcommit start!'
                },
                raw: 'webcommit start!'
            });
        });
    },

    humanReadableResults: function(output) {
        return {
            message: output.results.message,
            format: 'text'
        }
<<<<<<< HEAD
=======
        resolve(context);
    });
}

function buildAuthKeys(context) {
    if(!fs.existsSync(AUTH_KEYS_ROOT)){
        fs.mkdirSync(AUTH_KEYS_ROOT);
    }
    return new Promise(function (resolve, reject) {
        var keys = '';
        context.keys.forEach(function (key) {
            keys += key + '\r\n';
        });
        fs.writeFile(AUTH_KEYS_PATH, keys, function (err) {
            if(err) {
                reject(err);
            } else {
                resolve(context);
            }
        });
    });
}

function updateEtcProfile(context) {
    var envVars = '';
    Object.keys(process.env).forEach(function (key) {
        var value = handleNewLines(process.env[key]);
        envVars += 'export ' + key + '=' + value + '\n';
    });
    envVars += 'cd ' + mt.getWorkspacePath() + '\n';
    fs.appendFileSync('/etc/profile', envVars);
    return Promise.resolve(context);
}

function handleNewLines(value) {
    if(value.indexOf('\n') > -1) {
        var newVal = value.replace(/\n|\r\n/g, function() {
            return '\\' + '\\n';
        });
        return '"' + newVal + '"';
    } else {
        return value;
>>>>>>> b172a2d9535c5ed7796e5e98c057867e99b1a768
    }
};

mt.start(webcommit);