'use strict';

var mt = require('microtools');
var fs = require('fs');

const WORKSPACE_LOC = 'workspace';
const KEYS_KEY = 'keys';
const UPDATE_ACTION = 'update';
const USERNAME_KEY = 'ownerId';
const EMAIL_KEY = 'email';
const UPDATE_SSH_ACTION = 'update_ssh';
const UPDATE_EMAIL_ACTION = 'update_email';
const AUTH_KEYS_PATH = '/root/.ssh/authorized_keys';

var webcommit = {
    name: 'webcommit',
    categories: [mt.TOOLS_CAT_CONNECTIVITY],
    topics: [mt.NIKKA_CAT_STATE],
    rootDir: __dirname,

    notify: function(note) {
        if(note.topic == mt.NIKKA_CAT_STATE) {
            if(note.details.changes) {
                var changes = note.details.changes;
                changes.forEach(function (change) {
                    if(change.location === WORKSPACE_LOC && change.action === UPDATE_ACTION) {
                        if(change.key === KEYS_KEY) {
                            mt.run({ task: UPDATE_SSH_ACTION });
                            return;
                        } else if(change.key === EMAIL_KEY) {
                            mt.run({ task: UPDATE_EMAIL_ACTION });
                            return;
                        }
                    }
                });
            }
        }
    },

    run: function(param) {
        if(!param) {
            // first run
            return getUsername({})
                .then(getEmail)
                .then(getSshKeys)
                .then(setGitIdentity)
                .then(buildAuthKeys)
                .then(updateEtcProfile)
                .then(function () {
                    return Promise.resolve({ statusCode: mt.SC_FINISHED_SUCCESSFULLY, results: { message: 'Set git identity and built authorized_keys file.' } });
                }).catch(function(err) {
                    return Promise.reject(err);
                });
        } else if(param.task === UPDATE_SSH_ACTION) {
            // run on ssh key change
            return getSshKeys({})
                .then(buildAuthKeys)
                .then(function () {
                    return Promise.resolve({ statusCode: mt.SC_FINISHED_SUCCESSFULLY, results: { message: 'Built authorized_keys file.' } });
                }).catch(function (err) {
                    return Promise.reject(err);
                });
        }
        else if(param.task === UPDATE_EMAIL_ACTION) {
            return getEmail({})
                .then(setGitIdentity)
                .then(function () {
                    return Promise.resolve({ statusCode: mt.SC_FINISHED_SUCCESSFULLY, results: { message: 'Updated git identity email' } });
                }).catch(function (err) {
                    return Promise.reject(err);
                });
        }
    },

    humanReadableResults: function(output) {
        return output.results;
    }
};

function getUsername(context) {
    return mt.getState(WORKSPACE_LOC, USERNAME_KEY)
        .then(function (response) {
            context.username = response.data;
            return Promise.resolve(context);
        });
}

function getEmail(context) {
    return mt.getState(WORKSPACE_LOC, EMAIL_KEY)
        .then(function (response) {
            context.email = response.data;
            return Promise.resolve(context);
        });
}

function getSshKeys(context) {
    return mt.getState(WORKSPACE_LOC, KEYS_KEY)
        .then(function (response) {
            context.keys = response.data;
            return Promise.resolve(context);
        });
}

function setGitIdentity(context) {
    return new Promise(function (resolve, reject) {
        var exec = require('child_process').exec;
        if(context.email) {
            exec('git config --global user.email ' + '"' + context.email + '"');
        }
        if(context.username) {
            exec('git config --global user.name ' + '"' + context.username + '"');
        }
        resolve(context);
    });
}

function buildAuthKeys(context) {
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
    }
}

mt.start(webcommit);

module.exports = webcommit;
