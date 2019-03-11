/**
 * Copyright 2018 TriggerMesh, Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

"use strict"

console.log("Hello from knative");

var exports = module.exports = function(name) {

    if (typeof name == 'object') {
        // Riff's runtime gives you an object even if data is POSTed without Content-Type, but it's an odd object
        if (Object.keys(name).length === 1 && name[Object.keys(name)[0]] === "") {
            name = JSON.stringify(name) + ' (you might want to try POSTing with a Content-Type header)';
        } else {
            name = JSON.stringify(name);
        }
    } else if (typeof name !== 'string') {
        console.log('Got argument type', typeof name, ':', name);
        name = 'error: Unexpected argument type ' + (typeof name);
    }

    var str = "Hello " + name + "\n";
    return str;

};
