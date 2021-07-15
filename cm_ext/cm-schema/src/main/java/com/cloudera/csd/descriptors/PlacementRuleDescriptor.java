// Licensed to Cloudera, Inc. under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  Cloudera, Inc. licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package com.cloudera.csd.descriptors;

import com.cloudera.csd.validation.references.annotations.ReferenceType;
import com.cloudera.csd.validation.references.annotations.Referencing;

import java.util.List;

import javax.validation.constraints.NotNull;

/**
 * Describes a rule about where a role can be placed. Only sub-interfaces are
 * interesting.
 */
public interface PlacementRuleDescriptor {

  public interface AlwaysWithRule extends PlacementRuleDescriptor {
    /**
     * Role type that determines where this role must always be located.
     * In wizards, this role will not be visible for manual assignment.
     * This role will automatically be assigned to the same host as
     * any roles of the specified type.
     */
    @NotNull
    @Referencing(type=ReferenceType.ROLE)
    String getRoleType();
  }

  public interface NeverWithRule extends PlacementRuleDescriptor {
    /**
     * Role types that cannot be placed on the same host as this role.
     */
    @NotNull
    @Referencing(type=ReferenceType.ROLE)
    List<String> getRoleTypes();
  }
}
