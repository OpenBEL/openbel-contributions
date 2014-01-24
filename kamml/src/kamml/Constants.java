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

/**
 * Constants.
 *
 * @author Nick Bargnesi
 */
class Constants {

    /** GraphML header. */
    final static String HEADER;
    /** Graph element. */
    final static String GRAPH;
    /** Data element. */
    final static String DATA_FMT;
    /** Node element format. */
    final static String NODE_FMT;
    /** Edge element format. */
    final static String EDGE_FMT;
    /** Key element format. */
    final static String KEY_FMT;
    /** GraphML footer. */
    final static String FOOTER;

    static {
        HEADER = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
                 "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"" +
                 " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
                 " xsi:schemaLocation=\"http://graphml.graphdrawing.org/" +
                 "xmlns http://graphml.graphdrawing.org/xmlns/1.0/graph" +
                 "ml.xsd\">\n";

        GRAPH = "<graph id=\"G\" edgedefault=\"directed\" parse.nod" +
                "eids=\"canonical\" parse.edgeids=\"canonical\" par" +
                "se.order=\"nodesfirst\">\n";

        DATA_FMT = "<data key=\"%s\">%s</data>\n";

        NODE_FMT = "<node id=\"%s\"><data key=\"key1\">%s</data>" +
                   "<data key=\"key2\">%s</data></node>\n";

        EDGE_FMT = "<edge id=\"%s\" source=\"%s\" target=\"%s\">" +
                   "<data key=\"key3\">%s</data></edge>\n";

        KEY_FMT = "<key id=\"%s\" for=\"%s\" attr.name=\"%s\" attr." +
                  "type=\"string\"/>\n";

        FOOTER = "</graph></graphml>\n";

    }

}