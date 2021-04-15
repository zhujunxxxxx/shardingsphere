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

grammar DDLStatement;

import Symbol, Keyword, OracleKeyword, Literals, BaseRule;

createTable
    : CREATE createTableSpecification TABLE tableName createSharingClause createDefinitionClause createMemOptimizeClause createParentClause
    ;

createIndex
    : CREATE createIndexSpecification INDEX indexName ON createIndexDefinitionClause usableSpecification? invalidationSpecification?
    ;

alterTable
    : ALTER TABLE tableName memOptimizeClause alterDefinitionClause enableDisableClauses
    ;

alterIndex
    : ALTER INDEX indexName alterIndexInformationClause
    ;

dropTable
    : DROP TABLE tableName (CASCADE CONSTRAINTS)? (PURGE)?
    ;
 
dropIndex
    : DROP INDEX indexName ONLINE? FORCE? ((DEFERRED|IMMEDIATE) INVALIDATION)?
    ;

truncateTable
    : TRUNCATE TABLE tableName materializedViewLogClause? dropReuseClause? CASCADE?
    ;

createTableSpecification
    : ((GLOBAL | PRIVATE) TEMPORARY | SHARDED | DUPLICATED)?
    ;

tablespaceClauseWithParen
    : LP_ tablespaceClause RP_
    ;

tablespaceClause
    : TABLESPACE ignoredIdentifier
    ;

domainIndexClause
    : indexTypeName
    ;

createSharingClause
    : (SHARING EQ_ (METADATA | DATA | EXTENDED DATA | NONE))?
    ;

createDefinitionClause
    : createRelationalTableClause | createObjectTableClause
    ;

createRelationalTableClause
    : (LP_ relationalProperties RP_)? collationClause? commitClause? physicalProperties? tableProperties?
    ;
    
createMemOptimizeClause
    : (MEMOPTIMIZE FOR READ)? (MEMOPTIMIZE FOR WRITE)? 
    ;    

createParentClause
    : (PARENT tableName)?
    ;

createObjectTableClause
    : OF objectName objectTableSubstitution? (LP_ objectProperties RP_)? (ON COMMIT (DELETE | PRESERVE) ROWS)?
    ;

relationalProperties
    : relationalProperty (COMMA_ relationalProperty)*
    ;

relationalProperty
    : columnDefinition | virtualColumnDefinition | outOfLineConstraint | outOfLineRefConstraint
    ;

columnDefinition
    : columnName dataType SORT? visibleClause (defaultNullClause expr | identityClause)? (ENCRYPT encryptionSpecification)? (inlineConstraint+ | inlineRefConstraint)?
    ;

visibleClause
    : (VISIBLE | INVISIBLE)?
    ;

defaultNullClause
    : DEFAULT (ON NULL)?
    ;

identityClause
    : GENERATED (ALWAYS | BY DEFAULT (ON NULL)?) AS IDENTITY identifyOptions
    ;

identifyOptions
    : LP_? (identityOption+)? RP_?
    ;

identityOption
    : START WITH (NUMBER_ | LIMIT VALUE)
    | INCREMENT BY NUMBER_
    | MAXVALUE NUMBER_
    | NOMAXVALUE
    | MINVALUE NUMBER_
    | NOMINVALUE
    | CYCLE
    | NOCYCLE
    | CACHE NUMBER_
    | NOCACHE
    | ORDER
    | NOORDER
    ;

encryptionSpecification
    : (USING STRING_)? (IDENTIFIED BY STRING_)? STRING_? (NO? SALT)?
    ;

inlineConstraint
    : (CONSTRAINT ignoredIdentifier)? (NOT? NULL | UNIQUE | primaryKey | referencesClause | CHECK LP_ expr RP_) constraintState?
    ;

referencesClause
    : REFERENCES tableName columnNames? (ON DELETE (CASCADE | SET NULL))?
    ;

constraintState
    : notDeferrable 
    | initiallyClause 
    | RELY | NORELY 
    | usingIndexClause 
    | ENABLE | DISABLE 
    | VALIDATE | NOVALIDATE 
    | exceptionsClause
    ;

notDeferrable
    : NOT? DEFERRABLE
    ;

initiallyClause
    : INITIALLY (IMMEDIATE | DEFERRED)
    ;

exceptionsClause
    : EXCEPTIONS INTO tableName
    ;

usingIndexClause
    : USING INDEX (indexName | createIndexClause)?
    ;

createIndexClause
    :  LP_ createIndex RP_
    ;

inlineRefConstraint
    : SCOPE IS tableName | WITH ROWID | (CONSTRAINT ignoredIdentifier)? referencesClause constraintState?
    ;

virtualColumnDefinition
    : columnName dataType? (GENERATED ALWAYS)? AS LP_ expr RP_ VIRTUAL? inlineConstraint*
    ;

outOfLineConstraint
    : (CONSTRAINT ignoredIdentifier)?
    (UNIQUE columnNames
    | primaryKey columnNames 
    | FOREIGN KEY columnNames referencesClause
    | CHECK LP_ expr RP_
    ) constraintState?
    ;

outOfLineRefConstraint
    : SCOPE FOR LP_ lobItem RP_ IS tableName
    | REF LP_ lobItem RP_ WITH ROWID
    | (CONSTRAINT ignoredIdentifier)? FOREIGN KEY lobItemList referencesClause constraintState?
    ;

createIndexSpecification
    : (UNIQUE | BITMAP)?
    ;

clusterIndexClause
    : CLUSTER clusterName indexAttributes?
    ;

indexAttributes
    : (ONLINE | (SORT|NOSORT) | REVERSE | (VISIBLE | INVISIBLE))
    ;

tableIndexClause
    : tableName alias? indexExpressions
    ;

indexExpressions
    : LP_? indexExpression (COMMA_ indexExpression)* RP_?
    ;

indexExpression
    : (columnName | expr) (ASC | DESC)?
    ;

bitmapJoinIndexClause
    : tableName columnSortsClause_ FROM tableAlias WHERE expr
    ;

columnSortsClause_
    : LP_? columnSortClause_ (COMMA_ columnSortClause_)* RP_?
    ;
    
columnSortClause_
    : (tableName | alias)? columnName (ASC | DESC)?
    ;

createIndexDefinitionClause
    : clusterIndexClause | tableIndexClause | bitmapJoinIndexClause
    ;

tableAlias
    : tableName alias? (COMMA_ tableName alias?)*
    ;

alterDefinitionClause
    : (alterTableProperties
    | columnClauses
    | constraintClauses
    | alterTablePartitioning ((DEFERRED| IMMEDIATE) INVALIDATION)?
    | alterExternalTable)?
    ;

alterTableProperties
    : renameTableSpecification | REKEY encryptionSpecification
    ;

renameTableSpecification
    : RENAME TO identifier
    ;

columnClauses
    : operateColumnClause+ | renameColumnClause
    ;

operateColumnClause
    : addColumnSpecification | modifyColumnSpecification | dropColumnClause
    ;

addColumnSpecification
    : ADD columnOrVirtualDefinitions columnProperties?
    ;

columnOrVirtualDefinitions
    : LP_? columnOrVirtualDefinition (COMMA_ columnOrVirtualDefinition)* RP_? | columnOrVirtualDefinition
    ;

columnOrVirtualDefinition
    : columnDefinition | virtualColumnDefinition
    ;

columnProperties
    : columnProperty+
    ;

columnProperty
    : objectTypeColProperties
    ;

objectTypeColProperties
    : COLUMN columnName substitutableColumnClause
    ;

substitutableColumnClause
    : ELEMENT? IS OF TYPE? LP_ ONLY? dataTypeName RP_ | NOT? SUBSTITUTABLE AT ALL LEVELS
    ;

modifyColumnSpecification
    : MODIFY (LP_? modifyColProperties (COMMA_ modifyColProperties)* RP_? | modifyColSubstitutable)
    ;

modifyColProperties
    : columnName dataType? (DEFAULT expr)? (ENCRYPT encryptionSpecification | DECRYPT)? inlineConstraint*
    ;

modifyColSubstitutable
    : COLUMN columnName NOT? SUBSTITUTABLE AT ALL LEVELS FORCE?
    ;

dropColumnClause
    : SET UNUSED columnOrColumnList cascadeOrInvalidate* | dropColumnSpecification
    ;

dropColumnSpecification
    : DROP columnOrColumnList cascadeOrInvalidate* checkpointNumber?
    ;

columnOrColumnList
    : (COLUMN columnName) | columnNames
    ;

cascadeOrInvalidate
    : CASCADE CONSTRAINTS | INVALIDATE
    ;

checkpointNumber
    : CHECKPOINT NUMBER_
    ;

renameColumnClause
    : RENAME COLUMN columnName TO columnName
    ;

constraintClauses
    : addConstraintSpecification | modifyConstraintClause | renameConstraintClause | dropConstraintClause+
    ;

addConstraintSpecification
    : ADD (outOfLineConstraint+ | outOfLineRefConstraint)
    ;

modifyConstraintClause
    : MODIFY constraintOption constraintState+ CASCADE?
    ;

constraintWithName
    : CONSTRAINT ignoredIdentifier
    ;

constraintOption
    : constraintWithName | constraintPrimaryOrUnique
    ;

constraintPrimaryOrUnique
    : primaryKey | UNIQUE columnNames
    ;

renameConstraintClause
    : RENAME constraintWithName TO ignoredIdentifier
    ;

dropConstraintClause
    : DROP
    (
    constraintPrimaryOrUnique CASCADE? ((KEEP | DROP) INDEX)? | (CONSTRAINT ignoredIdentifier CASCADE?)
    ) 
    ;

alterExternalTable
    : (addColumnSpecification | modifyColumnSpecification | dropColumnSpecification)+
    ;

objectProperties
    : objectProperty (COMMA_ objectProperty)*
    ;

objectProperty
    : (columnName | attributeName) (DEFAULT expr)? (inlineConstraint* | inlineRefConstraint?) | outOfLineConstraint | outOfLineRefConstraint
    ;

alterIndexInformationClause
    : rebuildClause ((DEFERRED|IMMEDIATE) | INVALIDATION)?
    | parallelClause
    | COMPILE
    | (ENABLE | DISABLE)
    | UNUSABLE ONLINE? ((DEFERRED|IMMEDIATE)|INVALIDATION)?
    | (VISIBLE | INVISIBLE)
    | renameIndexClause
    | COALESCE CLEANUP? ONLY? parallelClause?
    | ((MONITORING | NOMONITORING) USAGE)
    | UPDATE BLOCK REFERENCES
    ;

renameIndexClause
    : (RENAME TO indexName)?
    ;
    
objectTableSubstitution
    : NOT? SUBSTITUTABLE AT ALL LEVELS
    ;

memOptimizeClause
    : memOptimizeReadClause? memOptimizeWriteClause?
    ;

memOptimizeReadClause
    : (MEMOPTIMIZE FOR READ | NO MEMOPTIMIZE FOR READ)
    ;

memOptimizeWriteClause
    : (MEMOPTIMIZE FOR WRITE | NO MEMOPTIMIZE FOR WRITE)
    ;

enableDisableClauses
    : (enableDisableClause | enableDisableOthers)?
    ;

enableDisableClause
    : (ENABLE | DISABLE) (VALIDATE |NO VALIDATE)? ((UNIQUE columnName (COMMA_ columnName)*) | PRIMARY KEY | constraintWithName) usingIndexClause? exceptionsClause? CASCADE? ((KEEP | DROP) INDEX)?
    ;

enableDisableOthers
    : (ENABLE | DISABLE) (TABLE LOCK | ALL TRIGGERS | CONTAINER_MAP | CONTAINERS_DEFAULT)
    ;

rebuildClause
    : REBUILD parallelClause?
    ;

parallelClause
    : NOPARALLEL | PARALLEL NUMBER_?
    ;

usableSpecification
    : (USABLE | UNUSABLE)
    ;

invalidationSpecification
    : (DEFERRED | IMMEDIATE) INVALIDATION
    ;

materializedViewLogClause
    : (PRESERVE | PURGE) MATERIALIZED VIEW LOG
    ;

dropReuseClause
    : (DROP (ALL)? | REUSE) STORAGE
    ;

collationClause
    : DEFAULT COLLATION collationName
    ;

commitClause
    : (ON COMMIT (DROP | PRESERVE) ROWS)? (ON COMMIT (DELETE | PRESERVE) ROWS)?
    ;

physicalProperties
    : deferredSegmentCreation? segmentAttributesClause tableCompression? inmemoryTableClause? ilmClause?
    | deferredSegmentCreation? (organizationClause?|externalPartitionClause?)
    | clusterClause
    ;

deferredSegmentCreation
    : SEGMENT CREATION (IMMEDIATE|DEFERRED)
    ;

segmentAttributesClause
    : physicalAttributesClause
    | (TABLESPACE tablespaceName | TABLESPACE SET tablespaceSetName)
    | loggingClause
    ;

physicalAttributesClause
    : (PCTFREE NUMBER_ | PCTUSED NUMBER_ | INITRANS NUMBER_ | storageClause)*
    ;

loggingClause
    : LOGGING | NOLOGGING |  FILESYSTEM_LIKE_LOGGING
    ;

storageClause
    : STORAGE LP_
    (INITIAL sizeClause
    | NEXT sizeClause
    | MINEXTENTS NUMBER_
    | MAXEXTENTS (NUMBER_ | UNLIMITED)
    | maxsizeClause
    | PCTINCREASE NUMBER_
    | FREELISTS NUMBER_
    | FREELIST GROUPS NUMBER_
    | OPTIMAL (sizeClause | NULL)?
    | BUFFER_POOL (KEEP | RECYCLE | DEFAULT)
    | FLASH_CACHE (KEEP | NONE | DEFAULT)
    | CELL_FLASH_CACHE (KEEP | NONE | DEFAULT)
    | ENCRYPT
    )+ RP_
    ;

sizeClause
    : NUMBER_ ('K' | 'M' | 'G' | 'T' | 'P' | 'E')?
    ;

maxsizeClause
    : MAXSIZE (UNLIMITED | sizeClause)
    ;

tableCompression
    : COMPRESS
    | ROW STORE COMPRESS (BASIC | ADVANCED)?
    | COLUMN STORE COMPRESS (FOR (QUERY | ARCHIVE) (LOW | HIGH)?)? (NO? ROW LEVEL LOCKING)?
    | NOCOMPRESS
    ;

inmemoryTableClause
    : ((INMEMORY inmemoryAttributes?) | NO INMEMORY)? (inmemoryColumnClause)?
    ;

inmemoryAttributes
    : inmemoryMemcompress? inmemoryPriority? inmemoryDistribute? inmemoryDuplicate?
    ;

inmemoryColumnClause
    : (INMEMORY inmemoryMemcompress? | NO INMEMORY) columnNames
    ;

inmemoryMemcompress
    : MEMCOMPRESS FOR ( DML | (QUERY | CAPACITY) (LOW | HIGH)? ) | NO MEMCOMPRESS
    ;

inmemoryPriority
    : PRIORITY (NONE | LOW | MEDIUM | HIGH | CRITICAL)
    ;

inmemoryDistribute
    : DISTRIBUTE (AUTO | BY (ROWID RANGE | PARTITION | SUBPARTITION))? (FOR SERVICE (DEFAULT | ALL | serviceName | NONE))?
    ;

inmemoryDuplicate
    : DUPLICATE | DUPLICATE ALL | NO DUPLICATE
    ;

ilmClause
    : ILM (ADD POLICY ilmPolicyClause
    | (DELETE | ENABLE | DISABLE) POLICY ilmPolicyName
    | (DELETE_ALL | ENABLE_ALL | DISABLE_ALL))
    ;

ilmPolicyClause
    : ilmCompressionPolicy | ilmTieringPolicy | ilmInmemoryPolicy
    ;

ilmCompressionPolicy
    : tableCompression (SEGMENT | GROUP) ( AFTER ilmTimePeriod OF ( NO ACCESS | NO MODIFICATION | CREATION ) | ON functionName)
    | (ROW STORE COMPRESS ADVANCED | COLUMN STORE COMPRESS FOR QUERY) ROW AFTER ilmTimePeriod OF NO MODIFICATION
    ;

ilmTimePeriod
    : NUMBER_ ((DAY | DAYS) | (MONTH | MONTHS) | (YEAR | YEARS))
    ;

ilmTieringPolicy
    : TIER TO tablespaceName (SEGMENT | GROUP)? (ON functionName)?
    | TIER TO tablespaceName READ ONLY (SEGMENT | GROUP)? (AFTER ilmTimePeriod OF (NO ACCESS | NO MODIFICATION | CREATION) | ON functionName)
    ;

ilmInmemoryPolicy
    : (SET INMEMORY inmemoryAttributes | MODIFY INMEMORY inmemoryMemcompress | NO INMEMORY) SEGMENT (AFTER ilmTimePeriod OF (NO ACCESS | NO MODIFICATION | CREATION) | ON functionName)
    ;

organizationClause
    : ORGANIZATION 
    ( HEAP segmentAttributesClause? heapOrgTableClause 
    | INDEX segmentAttributesClause? indexOrgTableClause 
    | EXTERNAL externalTableClause)
    ;

heapOrgTableClause
    : tableCompression? inmemoryTableClause? ilmClause?
    ;

indexOrgTableClause
    : (mappingTableClause | PCTTHRESHOLD NUMBER_ | prefixCompression)* indexOrgOverflowClause?
    ;

externalTableClause
    : LP_ (TYPE accessDriverType)? (externalTableDataProps)? RP_ (REJECT LIMIT (NUMBER_ | UNLIMITED))? inmemoryTableClause?
    ;

externalTableDataProps
    : (DEFAULT DIRECTORY directoryName)? (ACCESS PARAMETERS ((opaqueFormatSpec) | USING CLOB subquery))? (LOCATION LP_ (directoryName COLON_)? locationSpecifier (COMMA_ (directoryName COLON_)? locationSpecifier)+ RP_)?
    ;

mappingTableClause
    : MAPPING TABLE | NOMAPPING
    ;

prefixCompression
    : COMPRESS NUMBER_? | NOCOMPRESS
    ;

indexOrgOverflowClause
    :  (INCLUDING columnName)? OVERFLOW segmentAttributesClause?
    ;

externalPartitionClause
    : EXTERNAL PARTITION ATTRIBUTES externalTableClause (REJECT LIMIT)?
    ;

clusterRelatedClause
    : CLUSTER clusterName columnNames
    ;

tableProperties
    :columnProperties?
     readOnlyClause?
     indexingClause?
     tablePartitioningClauses?
     attributeClusteringClause?
     (CACHE | NOCACHE)?
     ( RESULT_CACHE ( MODE (DEFAULT | FORCE) ) )?
     parallelClause?
     (ROWDEPENDENCIES | NOROWDEPENDENCIES)?
     enableDisableClause*
     rowMovementClause?
     flashbackArchiveClause?
     (ROW ARCHIVAL)?
     (AS subquery | FOR EXCHANGE WITH TABLE tableName)?
    ;

readOnlyClause
    : READ ONLY | READ WRITE 
    ;

indexingClause
    : INDEXING (ON | OFF)
    ;

tablePartitioningClauses
    : rangePartitions
    | listPartitions
    | hashPartitions
    | compositeRangePartitions
    | compositeListPartitions
    | compositeHashPartitions
    | referencePartitioning
    | systemPartitioning
    | consistentHashPartitions
    | consistentHashWithSubpartitions
    | partitionsetClauses
    ;

rangePartitions
    : PARTITION BY RANGE columnNames
      (INTERVAL LP_ expr RP_ (STORE IN LP_ tablespaceName (COMMA_ tablespaceName)* RP_)?)?
      LP_ PARTITION partition? rangeValuesClause tablePartitionDescription (COMMA_ PARTITION partition? rangeValuesClause tablePartitionDescription externalPartSubpartDataProps?)* RP_
    ;

rangeValuesClause
    : VALUES LESS THAN LP_? (numberLiterals | MAXVALUE) (COMMA_ (numberLiterals | MAXVALUE))* RP_?
    ;

tablePartitionDescription
    : (INTERNAL | EXTERNAL)?
      deferredSegmentCreation?
      readOnlyClause?
      indexingClause?
      segmentAttributesClause?
      (tableCompression | prefixCompression)?
      inmemoryClause?
      ilmClause?
      (OVERFLOW segmentAttributesClause?)?
      (lobStorageClause | varrayColProperties | nestedTableColProperties)*
    ;

inmemoryClause
    : INMEMORY inmemoryAttributes? | NO INMEMORY
    ;

varrayColProperties
    : VARRAY varrayItem (substitutableColumnClause? varrayStorageClause | substitutableColumnClause)
    ;

nestedTableColProperties
    : NESTED TABLE 
    (nestedItem | COLUMN_VALUE) substitutableColumnClause? (LOCAL | GLOBAL)? STORE AS storageTable 
    LP_ (LP_ objectProperties RP_ | physicalProperties | columnProperties) RP_ 
    (RETURN AS? (LOCATOR | VALUE))?
    ;

lobStorageClause
    : LOB
    ( LP_ lobItem (COMMA_ lobItem)* RP_ STORE AS ((SECUREFILE | BASICFILE) | LP_ lobStorageParameters RP_)+
    | LP_ lobItem RP_ STORE AS ((SECUREFILE | BASICFILE) | lobSegname | LP_ lobStorageParameters RP_)+
    )
    ;

varrayStorageClause
    : STORE AS (SECUREFILE | BASICFILE)? LOB (lobSegname? LP_ lobStorageParameters RP_ | lobSegname)
    ;

lobStorageParameters
    : ((TABLESPACE tablespaceName | TABLESPACE SET tablespaceSetName) | lobParameters storageClause?)+ | storageClause
    ;

lobParameters
    : ( (ENABLE | DISABLE) STORAGE IN ROW
        | CHUNK NUMBER_
        | PCTVERSION NUMBER_
        | FREEPOOLS NUMBER_
        | lobRetentionClause
        | lobDeduplicateClause
        | lobCompressionClause
        | (ENCRYPT encryptionSpecification | DECRYPT)
        | (CACHE | NOCACHE | CACHE READS) loggingClause? 
      )+
    ;

lobRetentionClause
    : RETENTION (MAX | MIN NUMBER_ | AUTO | NONE)?
    ;

lobDeduplicateClause
    : DEDUPLICATE | KEEP_DUPLICATES
    ;

lobCompressionClause
    : (COMPRESS (HIGH | MEDIUM | LOW)? | NOCOMPRESS)
    ;

externalPartSubpartDataProps
    : (DEFAULT DIRECTORY directoryName) (LOCATION LP_ (directoryName COLON_)? locationSpecifier (COMMA_ (directoryName COLON_)? locationSpecifier)* RP_)?
    ;

listPartitions
    : PARTITION BY LIST columnNames
      (AUTOMATIC (STORE IN LP_? tablespaceName (COMMA_ tablespaceName)* RP_?))?
      LP_ PARTITION partition? listValuesClause tablePartitionDescription (COMMA_ PARTITION partition? listValuesClause tablePartitionDescription externalPartSubpartDataProps?)* RP_
    ;

listValuesClause
    : VALUES ( listValues | DEFAULT )
    ;

listValues
    : (literals | NULL) (COMMA_ (literals | NULL))*
    | (LP_? ( (literals | NULL) (COMMA_ (literals | NULL))* ) RP_?) (COMMA_ LP_? ( (literals | NULL) (COMMA_ (literals | NULL))* ) RP_?)*
    ;

hashPartitions
    : PARTITION BY HASH columnNames (individualHashPartitions | hashPartitionsByQuantity)
    ;

hashPartitionsByQuantity
    : PARTITIONS NUMBER_ (STORE IN (tablespaceName (COMMA_ tablespaceName)*))? (tableCompression | indexCompression)? (OVERFLOW STORE IN (tablespaceName (COMMA_ tablespaceName)*))?
    ;

indexCompression
    : prefixCompression | advancedIndexCompression
    ;

advancedIndexCompression
    : COMPRESS ADVANCED (LOW | HIGH)? | NOCOMPRESS
    ;

individualHashPartitions
    : LP_? (PARTITION partition? readOnlyClause? indexingClause? partitioningStorageClause?) (COMMA_ PARTITION partition? readOnlyClause? indexingClause? partitioningStorageClause?)* RP_?
    ;

partitioningStorageClause
    : ((TABLESPACE tablespaceName | TABLESPACE SET tablespaceSetName)
    | OVERFLOW (TABLESPACE tablespaceName | TABLESPACE SET tablespaceSetName)?
    | tableCompression
    | indexCompression
    | inmemoryClause
    | ilmClause
    | lobPartitioningStorage
    | VARRAY varrayItem STORE AS (SECUREFILE | BASICFILE)? LOB lobSegname
    )*
    ;

lobPartitioningStorage
    :LOB LP_ lobItem RP_ STORE AS (BASICFILE | SECUREFILE)?
    (lobSegname (LP_ TABLESPACE tablespaceName | TABLESPACE SET tablespaceSetName RP_)?
    | LP_ TABLESPACE tablespaceName | TABLESPACE SET tablespaceSetName RP_
    )?
    ;

compositeRangePartitions
    : PARTITION BY RANGE columnNames 
      (INTERVAL LP_ expr RP_ (STORE IN LP_? tablespaceName (COMMA_ tablespaceName)* RP_?)?)?
      (subpartitionByRange | subpartitionByList | subpartitionByHash) 
      LP_? rangePartitionDesc (COMMA_ rangePartitionDesc)* RP_?
    ;

subpartitionByRange
    : SUBPARTITION BY RANGE columnNames subpartitionTemplate?
    ;

subpartitionByList
    : SUBPARTITION BY LIST columnNames subpartitionTemplate?
    ;

subpartitionByHash
    : SUBPARTITION BY HASH columnNames (SUBPARTITIONS NUMBER_ (STORE IN LP_ tablespaceName (COMMA_ tablespaceName)? RP_)? | subpartitionTemplate)?
    ;

subpartitionTemplate
    : SUBPARTITION TEMPLATE
    (LP_? rangeSubpartitionDesc (COMMA_ rangeSubpartitionDesc)* | listSubpartitionDesc (COMMA_ listSubpartitionDesc)* | individualHashSubparts (COMMA_ individualHashSubparts)* RP_?)
    | hashSubpartitionQuantity
    ;

rangeSubpartitionDesc
    : SUBPARTITION subpartitionName? rangeValuesClause readOnlyClause? indexingClause? partitioningStorageClause? externalPartSubpartDataProps?
    ;

listSubpartitionDesc
    : SUBPARTITION subpartitionName? listValuesClause readOnlyClause? indexingClause? partitioningStorageClause? externalPartSubpartDataProps?
    ;

individualHashSubparts
    : SUBPARTITION subpartitionName? readOnlyClause? indexingClause? partitioningStorageClause?
    ;

rangePartitionDesc
    : PARTITION partitionName? rangeValuesClause tablePartitionDescription
    ((LP_? rangeSubpartitionDesc (COMMA_ rangeSubpartitionDesc)* | listSubpartitionDesc (COMMA_ listSubpartitionDesc)* | individualHashSubparts (COMMA_ individualHashSubparts)* RP_?)
    | hashSubpartitionQuantity)?
    ;

compositeListPartitions
    : PARTITION BY LIST columnNames 
      (AUTOMATIC (STORE IN LP_? tablespaceName (COMMA_ tablespaceName)* RP_?)?)?
      (subpartitionByRange | subpartitionByList | subpartitionByHash) 
      LP_? listPartitionDesc (COMMA_ listPartitionDesc)* RP_?
    ;

listPartitionDesc
    : PARTITIONSET partitionSetName listValuesClause (TABLESPACE SET tablespaceSetName)? lobStorageClause? (SUBPARTITIONS STORE IN LP_? tablespaceSetName (COMMA_ tablespaceSetName)* RP_?)?
    ;

compositeHashPartitions
    : PARTITION BY HASH columnNames (subpartitionByRange | subpartitionByList | subpartitionByHash) (individualHashPartitions | hashPartitionsByQuantity)
    ;

referencePartitioning
    :PARTITION BY REFERENCE LP_ constraint RP_ (LP_? referencePartitionDesc (COMMA_ referencePartitionDesc)* RP_?)?
    ;

referencePartitionDesc
    : PARTITION partition? tablePartitionDescription?
    ;

constraint
    : inlineConstraint | outOfLineConstraint | inlineRefConstraint | outOfLineRefConstraint
    ;

systemPartitioning
    : PARTITION BY SYSTEM (PARTITIONS NUMBER_ | referencePartitionDesc (COMMA_ referencePartitionDesc)*)?
    ;

consistentHashPartitions
    : PARTITION BY CONSISTENT HASH columnNames (PARTITIONS AUTO)? TABLESPACE SET tablespaceSetName
    ;

consistentHashWithSubpartitions
    : PARTITION BY CONSISTENT HASH columnNames (subpartitionByRange | subpartitionByList | subpartitionByHash)  (PARTITIONS AUTO)?
    ;

partitionsetClauses
    : rangePartitionsetClause | listPartitionsetClause
    ;

rangePartitionsetClause
    : PARTITIONSET BY RANGE columnNames PARTITION BY CONSISTENT HASH columnNames
      (SUBPARTITION BY ((RANGE | HASH) columnNames | LIST LP_ columnName LP_) subpartitionTemplate?)?
      PARTITIONS AUTO LP_ rangePartitionsetDesc (COMMA_ rangePartitionsetDesc)* RP_
    ;

rangePartitionsetDesc
    : PARTITIONSET partitionSetName rangeValuesClause (TABLESPACE SET tablespaceSetName)? (lobStorageClause)? (SUBPARTITIONS STORE IN tablespaceSetName?)?
    ;

listPartitionsetClause
    : PARTITIONSET BY RANGE LP_ columnName RP_ PARTITION BY CONSISTENT HASH columnNames
      (SUBPARTITION BY ((RANGE | HASH) columnNames | LIST LP_ columnName LP_) subpartitionTemplate?)?
      PARTITIONS AUTO LP_ rangePartitionsetDesc (COMMA_ rangePartitionsetDesc)* RP_
    ;

attributeClusteringClause
    : CLUSTERING clusteringJoin? clusterClause clusteringWhen? zonemapClause?
    ;

clusteringJoin
    : tableName (JOIN tableName ON LP_ expr RP_)+
    ;

clusterClause
    : BY (LINEAR | INTERLEAVED)? ORDER clusteringColumns
    ;

clusteringColumns
    : LP_? clusteringColumnGroup (COMMA_ clusteringColumnGroup)* RP_?
    ;

clusteringColumnGroup
    : columnNames
    ;

clusteringWhen
    : ((YES | NO) ON LOAD)? ((YES | NO) ON DATA MOVEMENT)?
    ;

zonemapClause
    : (WITH MATERIALIZED ZONEMAP (LP_ zonemapName RP_)?) | (WITHOUT MATERIALIZED ZONEMAP)
    ;

rowMovementClause
    : (ENABLE | DISABLE) ROW MOVEMENT
    ;

flashbackArchiveClause
    : FLASHBACK ARCHIVE flashbackArchiveName? | NO FLASHBACK ARCHIVE
    ;

alterSynonym
    : ALTER PUBLIC? SYNONYM (schemaName DOT_)? synonymName (COMPILE | EDITIONABLE | NONEDITIONABLE)
    ;

alterTablePartitioning
    : modifyTablePartition
    | moveTablePartition
    | addTablePartition
    | coalesceTablePartition
    | dropTablePartition
    ;

modifyTablePartition
    : modifyRangePartition
    | modifyHashPartition
    | modifyListPartition
    ;

modifyRangePartition
    : MODIFY partitionExtendedName (partitionAttributes
    | (addRangeSubpartition | addHashSubpartition | addListSubpartition)
    | coalesceTableSubpartition | alterMappingTableClauses | REBUILD? UNUSABLE LOCAL INDEXES
    | readOnlyClause | indexingClause)
    ;

modifyHashPartition
    : MODIFY partitionExtendedName (partitionAttributes | coalesceTableSubpartition
    | alterMappingTableClauses | REBUILD? UNUSABLE LOCAL INDEXES | readOnlyClause | indexingClause)
    ;

modifyListPartition
    : MODIFY partitionExtendedName (partitionAttributes
    | (ADD | DROP) VALUES LP_ listValues RP_
    | (addRangeSubpartition | addHashSubpartition | addListSubpartition)
    | coalesceTableSubpartition | REBUILD? UNUSABLE LOCAL INDEXES | readOnlyClause | indexingClause)
    ;

partitionExtendedName
    : PARTITION partition
    | PARTITION FOR LR_ partitionKeyValue (COMMA_ partitionKeyValue)* RP_
    ;

partitionKeyValue
    : partition (COMMA_ partition)*
    ;

addRangeSubpartition
    : ADD rangeSubpartitionDesc (COMMA_ rangeSubpartitionDesc)* dependentTablesClause? updateIndexClauses?
    ;

dependentTablesClause
    : DEPENDENT TABLES LP_ tableName LP_ partitionSpec (COMMA_ partitionSpec)* RP_
    (tableName LP_ partitionSpec (COMMA_ partitionSpec)* RP_)* RP_
    ;

addHashSubpartition
    : ADD individualHashSubparts dependentTablesClause? updateIndexClauses? parallelClause?
    ;

addListSubpartition
    : ADD listSubpartitionDesc (COMMA_ listSubpartitionDesc)* dependentTablesClause? updateIndexClauses?
    ;

coalesceTableSubpartition
    : COALESCE SUBPARTITION subpartition updateIndexClauses? parallelClause? allowDisallowClustering?
    ;

allowDisallowClustering
    : (ALLOW | DISALLOW) CLUSTERING
    ;

alterMappingTableClauses
    : MAPPING TABLE (allocateExtentClause | deallocateUnusedClause)
    ;

deallocateUnusedClause
    : DEALLOCATE UNUSED (KEEP sizeClause)?
    ;

allocateExtentClause
    : ALLOCATE EXTENT (LP_ (SIZE sizeClause | DATAFILE SQ_ fileName SQ_ | INSTANCE NUMBER_) RP_)?
    ;

updateIndexClauses
    : updateGlobalIndexClause | updateAllIndexesClause
    ;

updateGlobalIndexClause
    : (UPDATE | INVALIDATE) GLOBAL INDEXES
    ;

updateAllIndexesClause
    : UPDATE INDEXES
    (LP_ index LP_ (updateIndexPartition | updateIndexSubpartition) RP_
    (COMMA_ index LP_ (updateIndexPartition | updateIndexSubpartition)RP_)* RP_)?
    ;

updateIndexPartition
    : indexPartitionDescription indexSubpartitionClause? (COMMA_ indexPartitionDescription indexSubpartitionClause?)*
    ;

indexPartitionDescription
    :PARTITION (partition
    ((segmentAttributesClause | indexCompression) | PARAMETERS LP_ SQ_ odciParameters SQ_ RP_ )?
    usableSpecification?)?
    ;

indexSubpartitionClause
    : STORE IN tablespace LP_ (COMMA_ tablespace)* RP_
    | LP_ SUBPARTITION subpartition? (TABLESPACE tablespace)? indexCompression? (USABLE | UNUSABLE)?
    (COMMA_ LP_ SUBPARTITION subpartition? (TABLESPACE tablespace)? indexCompression? (USABLE | UNUSABLE)?)* RP_
    ;

updateIndexSubpartition
    : SUBPARTITION subpartition? (TABLESPACE tablespace)?
    (COMMA_ SUBPARTITION subpartition? (TABLESPACE tablespace)?)*
    ;

partitionSpec
    : PARTITION partition? tablePartitionDescription?
    ;

partitionAttributes
    : (physicalAttributesClause | loggingClause | allocateExtentClause | deallocateUnusedClause | shrinkClause)?
      (OVERFLOW (physicalAttributesClause | loggingClause | allocateExtentClause | deallocateUnusedClause)?)?
      tableCompression? inmemoryClause?
    ;

shrinkClause
    : SHRINK SPACE COMPACT? CASCADE?
    ;

moveTablePartition
    : MOVE partitionExtendedName (MAPPING TABLE)? tablePartitionDescription? filterCondition? updateAllIndexesClause? parallelClause? allowDisallowClustering? ONLINE?
    ;

filterCondition
    : INCLUDING ROWS whereClause
    ;

whereClause
    : WHERE expr
    ;

addTablePartition
    : ADD ((PARTITION partition? addRangePartitionClause (COMMA_ PARTITION partition? addRangePartitionClause)*)
        |  (PARTITION partition? addListPartitionClause (COMMA_ PARTITION partition? addListPartitionClause)*)
        |  (PARTITION partition? addSystemPartitionClause (COMMA_ PARTITION partition? addSystemPartitionClause)*)
        |  (PARTITION partition? addHashPartitionClause (COMMA_ PARTITION partition? addHashPartitionClause)*)
        ) dependentTablesClause?
    ;

addRangePartitionClause
    : rangeValuesClause tablePartitionDescription? externalPartSubpartDataProps?
    ((LP_? rangeSubpartitionDesc (COMMA_ rangeSubpartitionDesc)* | listSubpartitionDesc (COMMA_ listSubpartitionDesc)* | individualHashSubparts (COMMA_ individualHashSubparts)* RP_?)
    | hashSubpartitionQuantity)? updateIndexClauses?
    ;

addListPartitionClause
    : listValuesClause tablePartitionDescription? externalPartSubpartDataProps?
    ((LP_? rangeSubpartitionDesc (COMMA_ rangeSubpartitionDesc)* | listSubpartitionDesc (COMMA_ listSubpartitionDesc)* | individualHashSubparts (COMMA_ individualHashSubparts)* RP_?)
    | hashSubpartitionQuantity)? updateIndexClauses?
    ;

addSystemPartitionClause
    : tablePartitionDescription? updateIndexClauses?
    ;

addHashPartitionClause
    : partitioningStorageClause updateIndexClauses? parallelClause? readOnlyClause? indexingClause?
    ;

coalesceTablePartition
    : COALESCE PARTITION updateIndexClauses? parallelClause? allowDisallowClustering?
    ;

dropTablePartition
    : DROP partitionExtendedNames (updateIndexClauses parallelClause?)?
    ;

partitionExtendedNames
    : (PARTITION | PARTITIONS) (partition | FOR LP_ partitionKeyValue (COMMA_ partitionKeyValue)* RP_)
    (COMMA_ partition | FOR LP_ partitionKeyValue (COMMA_ partitionKeyValue)* RP_)*
    ;
