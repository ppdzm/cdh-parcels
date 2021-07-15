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
package com.cloudera.csd.validation.references.constraints;

import com.cloudera.csd.validation.references.DescriptorPath;
import com.cloudera.csd.validation.references.DescriptorPath.DescriptorNode;
import com.cloudera.csd.validation.references.DescriptorPath.PropertyDescriptorNode;
import com.cloudera.csd.validation.references.annotations.Referencing;
import com.cloudera.csd.validation.references.annotations.ReferenceType;
import com.cloudera.csd.validation.references.components.DescriptorPathImpl.PropertyNode;
import com.google.common.base.Joiner;
import com.google.common.collect.Lists;
import com.google.common.collect.SetMultimap;

import java.lang.annotation.Annotation;
import java.lang.annotation.ElementType;
import java.lang.reflect.Method;
import java.util.Collection;
import java.util.List;
import java.util.Set;

import javax.validation.ConstraintViolation;

/**
 * A reference constraint that checks references to entities. If a property is
 * annotated with {@link com.cloudera.csd.validation.references.annotations.Referencing}
 * then this constraint checks the entity is valid.
 * @param <T> the type of the root object
 */
public class ReferencedEntityConstraint<T> extends AbstractReferenceConstraint<T> {

  private static final Joiner JOINER = Joiner.on(", ");
  private static final String ERROR_MSG = "has invalid reference: %s. References available: [%s]";

  @Override
  public Class<? extends DescriptorNode> getNodeType() {
    return PropertyDescriptorNode.class;
  }

  @Override
  public Class<? extends Annotation> getAnnotationType() {
    return Referencing.class;
  }

  @Override
  public List<ConstraintViolation<T>> checkConstraint(Annotation annotation,
                                                      Object obj,
                                                      DescriptorPath path,
                                                      SetMultimap<ReferenceType, String> allowedRefs) {
    Referencing ref = (Referencing)annotation;
    Method method = path.getHeadNode().as(PropertyNode.class).getMethod();
    Collection<String> ids = getIds(method, obj);

    Set<String> candidates = allowedRefs.get(ref.type());
    List<ConstraintViolation<T>> errors = Lists.newArrayList();
    for (String id : ids) {
      if (!candidates.contains(id)) {
        errors.add(createViolation(id, path, candidates));
      }
    }
    return errors;
  }

  private ConstraintViolation<T> createViolation(String id, DescriptorPath path, Set<String> candidates) {
    return ReferenceConstraintViolation.forViolation(String.format(ERROR_MSG, id, JOINER.join(candidates)),
                                                     path.getHeadNode(),
                                                     id,
                                                     path,
                                                     ElementType.TYPE);
  }
}
