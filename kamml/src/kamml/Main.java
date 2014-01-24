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
import static org.openbel.framework.common.cfg.SystemConfiguration.*;

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
        fw.close();
        file.close();

        KAMStoreDao dao = new KAMStoreDaoImpl(ki.getSchemaName(), dbc);

        AllocatingIterator<SimpleKAMNode> nodeiter = dao.iterateNodes();
        while (nodeiter.hasNext()) {
            SimpleKAMNode node = nodeiter.next();
        }
        nodeiter.close();

        AllocatingIterator<SimpleKAMEdge> edgeiter = dao.iterateEdges();
        while (edgeiter.hasNext()) {
            SimpleKAMEdge edge = edgeiter.next();
            int srcID = edge.getSourceID();
            int tgtID = edge.getTargetID();
        }
        edgeiter.close();
    }

}

