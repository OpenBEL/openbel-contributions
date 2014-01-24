/*
 * Copyright (C) 2014 Selventa, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package kamml;

import static java.lang.String.format;
import static kamml.Constants.*;

/**
 * Utilities.
 *
 * @author Nick Bargnesi
 */
class Utilities {

    /** Create a data element. */
    static String makeData(String key,
                           String value) {
        return format(DATA_FMT, key, value);
    }

    /** Create a node element. */
    static String makeNode(String id,
                           String function,
                           String label) {
        label = label.replace("&", "&amp;");
        label = label.replace("\"", "&quot;");
        label = label.replace("'", "&apos;");
        return format(NODE_FMT, id, function, label);
    }

    /** Create an edge element. */
    static String makeEdge(String id,
                           String source,
                           String target,
                           String relationship) {
        return format(EDGE_FMT, id, source, target, relationship);
    }

    /** Create a key element. */
    static String makeKey(String id,
                          String for_,
                          String attrname) {
        return format(KEY_FMT, id, for_, attrname);
    }

}
