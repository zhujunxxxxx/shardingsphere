/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.shardingsphere.driver.jdbc.core.connection;

import com.google.common.collect.Multimap;
import lombok.SneakyThrows;
import org.apache.shardingsphere.driver.jdbc.core.fixture.BASEShardingSphereTransactionManagerFixture;
import org.apache.shardingsphere.driver.jdbc.core.fixture.XAShardingSphereTransactionManagerFixture;
import org.apache.shardingsphere.infra.database.DefaultSchema;
import org.apache.shardingsphere.infra.database.type.DatabaseTypeRegistry;
import org.apache.shardingsphere.infra.metadata.ShardingSphereMetaData;
import org.apache.shardingsphere.mode.manager.ContextManager;
import org.apache.shardingsphere.mode.metadata.MetaDataContexts;
import org.apache.shardingsphere.sharding.api.config.ShardingRuleConfiguration;
import org.apache.shardingsphere.sharding.api.config.rule.ShardingTableRuleConfiguration;
import org.apache.shardingsphere.transaction.ShardingSphereTransactionManagerEngine;
import org.apache.shardingsphere.transaction.TransactionHolder;
import org.apache.shardingsphere.transaction.config.TransactionRuleConfiguration;
import org.apache.shardingsphere.transaction.context.TransactionContexts;
import org.apache.shardingsphere.transaction.core.TransactionOperationType;
import org.apache.shardingsphere.transaction.core.TransactionType;
import org.apache.shardingsphere.transaction.core.TransactionTypeHolder;
import org.apache.shardingsphere.transaction.rule.TransactionRule;
import org.junit.After;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import javax.sql.DataSource;
import java.lang.reflect.Field;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.RETURNS_DEEP_STUBS;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

public final class ShardingSphereConnectionTest {
    
    private static Map<String, DataSource> dataSourceMap;
    
    private ShardingSphereConnection connection;
    
    private MetaDataContexts metaDataContexts;
    
    private TransactionContexts transactionContexts;
    
    @BeforeClass
    public static void init() throws SQLException {
        DataSource primaryDataSource = mockDataSource();
        DataSource replicaDataSource = mockDataSource();
        dataSourceMap = new HashMap<>(2, 1);
        dataSourceMap.put("test_primary_ds", primaryDataSource);
        dataSourceMap.put("test_replica_ds", replicaDataSource);
    }
    
    private static DataSource mockDataSource() throws SQLException {
        DataSource result = mock(DataSource.class);
        when(result.getConnection()).thenReturn(mock(Connection.class));
        return result;
    }
    
    @Before
    public void setUp() {
        metaDataContexts = mock(MetaDataContexts.class, RETURNS_DEEP_STUBS);
        ShardingSphereMetaData metaData = mock(ShardingSphereMetaData.class);
        when(metaDataContexts.getMetaData(DefaultSchema.LOGIC_NAME).getResource().getDatabaseType()).thenReturn(DatabaseTypeRegistry.getActualDatabaseType("H2"));
        when(metaDataContexts.getMetaData(DefaultSchema.LOGIC_NAME)).thenReturn(metaData);
        transactionContexts = mock(TransactionContexts.class);
        when(transactionContexts.getEngines()).thenReturn(mock(Map.class));
        when(transactionContexts.getEngines().get(DefaultSchema.LOGIC_NAME)).thenReturn(new ShardingSphereTransactionManagerEngine());
        ShardingRuleConfiguration shardingRuleConfig = new ShardingRuleConfiguration();
        shardingRuleConfig.getTables().add(new ShardingTableRuleConfiguration("test"));
        ContextManager contextManager = mock(ContextManager.class, RETURNS_DEEP_STUBS);
        when(contextManager.getMetaDataContexts()).thenReturn(metaDataContexts);
        when(contextManager.getTransactionContexts()).thenReturn(transactionContexts);
        when(contextManager.getDataSourceMap(DefaultSchema.LOGIC_NAME)).thenReturn(dataSourceMap);
        when(contextManager.getMetaDataContexts().getGlobalRuleMetaData().findSingleRule(TransactionRule.class)).thenReturn(Optional.empty());
        connection = new ShardingSphereConnection(DefaultSchema.LOGIC_NAME, contextManager);
        connection = new ShardingSphereConnection(DefaultSchema.LOGIC_NAME, contextManager);
    }
    
    @After
    public void clear() {
        try {
            connection.close();
            TransactionTypeHolder.clear();
            XAShardingSphereTransactionManagerFixture.getInvocations().clear();
            BASEShardingSphereTransactionManagerFixture.getInvocations().clear();
        } catch (final SQLException ignored) {
        }
    }
    
    @Test
    public void assertGetConnectionFromCache() throws SQLException {
        assertThat(connection.getConnection("test_primary_ds"), is(connection.getConnection("test_primary_ds")));
    }
    
    @Test(expected = IllegalStateException.class)
    public void assertGetConnectionFailure() throws SQLException {
        connection.getConnection("not_exist");
    }
    
    @Test
    public void assertLOCALTransactionOperation() throws SQLException {
        connection.setAutoCommit(true);
        assertFalse(TransactionHolder.isTransaction());
        connection.setAutoCommit(false);
        assertTrue(TransactionHolder.isTransaction());
    }
    
    @Test
    public void assertXATransactionOperation() throws SQLException {
        ContextManager contextManager = mock(ContextManager.class, RETURNS_DEEP_STUBS);
        when(contextManager.getMetaDataContexts()).thenReturn(metaDataContexts);
        when(contextManager.getTransactionContexts()).thenReturn(transactionContexts);
        when(contextManager.getDataSourceMap(DefaultSchema.LOGIC_NAME)).thenReturn(dataSourceMap);
        when(contextManager.getDataSourceMap(DefaultSchema.LOGIC_NAME)).thenReturn(dataSourceMap);
        TransactionRule transactionRule = new TransactionRule(new TransactionRuleConfiguration("XA", null));
        when(contextManager.getMetaDataContexts().getGlobalRuleMetaData().findSingleRule(TransactionRule.class)).thenReturn(Optional.of(transactionRule));
        connection = new ShardingSphereConnection(connection.getSchemaName(), contextManager);
        connection.setAutoCommit(false);
        assertTrue(XAShardingSphereTransactionManagerFixture.getInvocations().contains(TransactionOperationType.BEGIN));
        connection.commit();
        assertTrue(XAShardingSphereTransactionManagerFixture.getInvocations().contains(TransactionOperationType.COMMIT));
        connection.rollback();
        assertTrue(XAShardingSphereTransactionManagerFixture.getInvocations().contains(TransactionOperationType.ROLLBACK));
    }
    
    @Test
    public void assertBASETransactionOperation() throws SQLException {
        ContextManager contextManager = mock(ContextManager.class, RETURNS_DEEP_STUBS);
        when(contextManager.getMetaDataContexts()).thenReturn(metaDataContexts);
        when(contextManager.getTransactionContexts()).thenReturn(transactionContexts);
        when(contextManager.getDataSourceMap(DefaultSchema.LOGIC_NAME)).thenReturn(dataSourceMap);
        when(contextManager.getDataSourceMap(DefaultSchema.LOGIC_NAME)).thenReturn(dataSourceMap);
        TransactionRule transactionRule = new TransactionRule(new TransactionRuleConfiguration("BASE", null));
        when(contextManager.getMetaDataContexts().getGlobalRuleMetaData().findSingleRule(TransactionRule.class)).thenReturn(Optional.of(transactionRule));
        connection = new ShardingSphereConnection(connection.getSchemaName(), contextManager);
        connection.setAutoCommit(false);
        assertTrue(BASEShardingSphereTransactionManagerFixture.getInvocations().contains(TransactionOperationType.BEGIN));
        connection.commit();
        assertTrue(BASEShardingSphereTransactionManagerFixture.getInvocations().contains(TransactionOperationType.COMMIT));
        connection.rollback();
        assertTrue(BASEShardingSphereTransactionManagerFixture.getInvocations().contains(TransactionOperationType.ROLLBACK));
    }
    
    @Test
    public void assertIsValid() throws SQLException {
        Connection primaryConnection = mock(Connection.class);
        Connection upReplicaConnection = mock(Connection.class);
        Connection downReplicaConnection = mock(Connection.class);
        when(primaryConnection.isValid(anyInt())).thenReturn(true);
        when(upReplicaConnection.isValid(anyInt())).thenReturn(true);
        when(downReplicaConnection.isValid(anyInt())).thenReturn(false);
        connection.getCachedConnections().put("test_primary", primaryConnection);
        connection.getCachedConnections().put("test_replica_up", upReplicaConnection);
        assertTrue(connection.isValid(0));
        connection.getCachedConnections().put("test_replica_down", downReplicaConnection);
        assertFalse(connection.isValid(0));
    }
    
    @Test
    public void assertSetReadOnly() throws SQLException {
        Connection connection = mock(Connection.class);
        ShardingSphereConnection actual = createShardingSphereConnection(connection);
        assertFalse(actual.isReadOnly());
        actual.setReadOnly(true);
        assertTrue(actual.isReadOnly());
        verify(connection).setReadOnly(true);
    }
    
    @Test
    public void assertGetTransactionIsolationWithoutCachedConnections() throws SQLException {
        assertThat(createShardingSphereConnection().getTransactionIsolation(), is(Connection.TRANSACTION_READ_UNCOMMITTED));
    }
    
    @Test
    public void assertSetTransactionIsolation() throws SQLException {
        Connection connection = mock(Connection.class);
        ShardingSphereConnection actual = createShardingSphereConnection(connection);
        actual.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
        verify(connection).setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
    }
    
    @SuppressWarnings("unchecked")
    @SneakyThrows(ReflectiveOperationException.class)
    private Multimap<String, Connection> getCachedConnections(final ShardingSphereConnection connectionAdapter) {
        Field field = ShardingSphereConnection.class.getDeclaredField("cachedConnections");
        field.setAccessible(true);
        return (Multimap<String, Connection>) field.get(connectionAdapter);
    }
    
    @Test
    public void assertClose() throws SQLException {
        ShardingSphereConnection actual = createShardingSphereConnection(mock(Connection.class));
        actual.close();
        assertTrue(actual.isClosed());
        assertTrue(getCachedConnections(actual).isEmpty());
    }
    
    @Test
    public void assertCloseShouldNotClearTransactionType() throws SQLException {
        ShardingSphereConnection actual = createShardingSphereConnection(mock(Connection.class));
        TransactionTypeHolder.set(TransactionType.XA);
        actual.close();
        assertTrue(actual.isClosed());
        assertTrue(getCachedConnections(actual).isEmpty());
        assertThat(TransactionTypeHolder.get(), is(TransactionType.XA));
    }
    
    private ShardingSphereConnection createShardingSphereConnection(final Connection... connections) {
        ContextManager contextManager = mock(ContextManager.class, RETURNS_DEEP_STUBS);
        when(contextManager.getMetaDataContexts().getGlobalRuleMetaData().findSingleRule(TransactionRule.class)).thenReturn(Optional.empty());
        ShardingSphereConnection result = new ShardingSphereConnection(DefaultSchema.LOGIC_NAME, contextManager);
        result.getCachedConnections().putAll("", Arrays.asList(connections));
        return result;
    }
}
