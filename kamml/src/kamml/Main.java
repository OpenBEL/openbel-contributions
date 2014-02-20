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

import static kamml.Constants.*;
import static kamml.Utilities.*;

import static java.lang.String.format;
import static org.openbel.framework.common.cfg.SystemConfiguration.*;
import static org.openbel.framework.common.enums.RelationshipType.*;

import java.io.*;
import java.util.*;

import org.openbel.framework.common.cfg.SystemConfiguration;
import org.openbel.framework.api.*;
import org.openbel.framework.api.internal.*;
import org.openbel.framework.api.internal.KAMCatalogDao.KamInfo;
import org.openbel.framework.common.enums.*;
import org.openbel.framework.core.df.*;

/**
 * Generates GraphML output for a KAM.
 *
 * @author Nick Bargnesi
 */
class Main {

    static void out(String msg) {
        System.out.println(msg);
    }

    public static void main(String... args) throws Exception {
        SystemConfiguration syscfg = createSystemConfiguration();
        String dburl = syscfg.getKamURL();
        String user = syscfg.getKamUser();
        String pass = syscfg.getKamPassword();
        String schema = syscfg.getKamCatalogSchema();
        String prefix = syscfg.getKamSchemaPrefix();
        out("Bootstrapped the BEL Framework.");

        DatabaseService ds = new DatabaseServiceImpl();
        DBConnection dbc = ds.dbConnection(dburl, user, pass);

        KAMCatalogDao catalog = new KAMCatalogDao(dbc, schema, prefix);
        KAMStore ks = new KAMStoreImpl(dbc);

        if (args.length != 2) {
            out("Printing available KAMs:");
            for (final KamInfo ki : ks.getCatalog()) {
                out("\t" + ki.getName());
            }
            System.exit(0);
        }

        String name = args[0];
        KamInfo ki = ks.getKamInfo(name);
        if (ki == null) {
            out("KAM \"" + name + "\" not found");
            System.exit(1);
        }
        out("Using KAM \"" + name + "\".");
        String filearg = args[1];
        File file = new File(filearg);
        FileWriter fw = new FileWriter(file);
        out("Using file \"" + file.getAbsolutePath() + "\".");

        fw.write(HEADER);
        fw.write(makeKey("key0", "graph", "name", "string"));
        fw.write(makeKey("key1", "node", "function", "string"));
        fw.write(makeKey("key2", "node", "label", "string"));
        fw.write(makeKey("key3", "edge", "relationship", "string"));
        fw.write(makeKey("key4", "edge", "causal", "boolean"));

        fw.write(GRAPH);
        fw.write(makeData("key0", name));

        KAMStoreDao dao = new KAMStoreDaoImpl(ki.getSchemaName(), dbc);

        AllocatingIterator<SimpleKAMNode> nodeiter = dao.iterateNodes();
        while (nodeiter.hasNext()) {
            SimpleKAMNode node = nodeiter.next();
            int id = node.getID();
            id = id - 1;
            String function = node.getFunction().getDisplayValue();
            String lbl = node.getLabel();
            fw.write(makeNode("n" + id, function, lbl));
        }
        nodeiter.close();

        AllocatingIterator<SimpleKAMEdge> edgeiter = dao.iterateEdges();
        while (edgeiter.hasNext()) {
            SimpleKAMEdge edge = edgeiter.next();
            int id = edge.getID();
            id = id - 1;
            RelationshipType rt = edge.getRelationship();
            String rel = rt.getDisplayValue();
            int src = edge.getSourceID();
            src = src - 1;
            int tgt = edge.getTargetID();
            tgt = tgt - 1;
            int causal;
            switch (rt) {
                case INCREASES:
                case DECREASES:
                case DIRECTLY_INCREASES:
                case DIRECTLY_DECREASES:
                case CAUSES_NO_CHANGE:
                case RATE_LIMITING_STEP_OF:
                    causal = 1;
                    break;
                default:
                    causal = 0;
                    break;
            }
            fw.write(makeEdge("e" + id, "n" + src, "n" + tgt, rel, causal));
        }
        fw.write(FOOTER);
        edgeiter.close();
        fw.close();
    }

}

