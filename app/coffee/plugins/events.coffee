# Copyright 2014 Andrey Antukh <niwi@niwi.be>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class EventsService
    constructor: (@win, @log, @config, @gmAuth) ->
        _.bindAll(@)

    initialize: (sessionId) ->
        @.sessionId = sessionId

        if @.win.WebSocket is undefined
            @.log.debug "WebSockets not supported on your browser"

    setupConnection: ->
        @.stopExistingConnection()

        wshost = @.config.get("eventsHost", "localhost:8888")
        wsscheme = @.config.get("eventsScheme", "ws")
        url = "#{wsscheme}://#{wshost}/events"

        @.ws = new @.win.WebSocket(url)
        @.ws.addEventListener("open", @.onOpen)
        @.ws.addEventListener("message", @.onMessage)
        @.ws.addEventListener("error", @.onError)
        @.ws.addEventListener("close", @.onClose)

    stopExistingConnection: ->
        if @.ws is undefined
            return

        @.ws.close()
        @.ws.removeEventListener("open", @.onOpen)
        @.ws.removeEventListener("close", @.onClose)
        @.ws.removeEventListener("error", @.onError)
        @.ws.removeEventListener("message", @.onMessage)

        delete @.ws

    onOpen: ->
        @.log.debug "WebSocket connection opened"

        connection_id = @.generateUniqueId()
        console.log("Connection id:", connection_id)
        @.ws.send('{"token": "eyJ1c2VyX2lkIjoxfQ:1WOArJ:V3yF_KGTslhJyMt09nhm00g-2Vc"}')

    onMessage: (event) ->
        @.log.debug "WebSocket message received: #{event.data}"

    onError: (error) ->
        @.log.error "WebSocket error: #{error}"

    onClose: ->
        @.log.debug "WebSocket closed."


class EventsProvider
    setSessionId: (sessionId) ->
        @.sessionId = sessionId

    $get: ($win, $log, $conf, $auth) ->
        service = new EventsService($win, $log, $conf, $auth)
        service.initialize(@.sessionId)
        return service

    @.prototype.$get.$inject = ["$window", "$log", "$gmConfig", "$gmAuth"]


module = angular.module("gmEvents", [])
module.provider("$gmEvents", EventsProvider)