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
package com.cloudera.csd.validation.constraints.components;

import com.cloudera.csd.validation.constraints.ValidServiceDependency;
import com.cloudera.csd.validation.constraints.ValidServiceDependencyValidator;

import java.util.Set;
import javax.validation.ConstraintValidatorContext;

/**
 * Implementation of ValidServiceDependency constraint based
 * on a static list of dependencies.
 */
public class ValidServiceDependencyValidatorImpl implements ValidServiceDependencyValidator {

  private final Set<String> validServiceTypes;

  public ValidServiceDependencyValidatorImpl(Set<String> validServiceTypes) {
    this.validServiceTypes = validServiceTypes;
  }

  @Override
  public void initialize(ValidServiceDependency constraintAnnotation) {}

  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    boolean isValid = validServiceTypes.contains(value);
    if (!isValid) {
      context.disableDefaultConstraintViolation();
      // Customizes the validation result message by adding the validation
      // target value at the end of the violation object path. It will be
      // something like:
      // serviceDependencies[1].name.SPARK
      context.buildConstraintViolationWithTemplate(
            context.getDefaultConstraintMessageTemplate()
          )
          .addPropertyNode(value)
          .addConstraintViolation();
    }

    return isValid;
  }
}
