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

import static com.cloudera.csd.validation.references.annotations.SubstitutionType.*;

import com.cloudera.csd.descriptors.InterfaceStability.Unstable;
import com.cloudera.csd.descriptors.dependencyExtension.DependencyExtension;
import com.cloudera.csd.descriptors.parameters.Parameter;
import com.cloudera.csd.validation.constraints.EntityTypeFormat;
import com.cloudera.csd.validation.constraints.UniqueField;
import com.cloudera.csd.validation.constraints.UniqueServiceType;
import com.cloudera.csd.validation.references.annotations.AvailableSubstitutions;
import com.cloudera.csd.validation.references.annotations.Named;
import com.cloudera.csd.validation.references.annotations.ReferenceType;
import com.cloudera.csd.validation.references.annotations.Referencing;

import java.util.List;
import java.util.Set;

import javax.validation.Valid;
import javax.validation.constraints.Min;

import org.hibernate.validator.constraints.NotBlank;

/**
 * The root interface that describes a new service type
 * for the CSD framework.
 */
@Named
public interface ServiceDescriptor {

  @EntityTypeFormat
  @UniqueServiceType
  String getName();

  @NotBlank
  String getLabel();

  @NotBlank
  String getDescription();

  @NotBlank
  String getVersion();

  @Valid
  CompatibilityDescriptor getCompatibility();

  @Min(1)
  Integer getMaxInstances();

  @Valid
  RunAs getRunAs();

  String getIcon();

  @Valid
  ParcelDescriptor getParcel();

  /**
   * When set to true, this service participates
   * in the express wizard.
   */
  boolean isInExpressWizard();

  /**
   * The list of roles that have external links
   * that should also be surfaced on the service.
   * It is recommended that this is a list of only
   * singleton/master roles.
   */
  @Referencing(type= ReferenceType.ROLE)
  Set<String> getRolesWithExternalLinks();

  @UniqueField("name")
  @Valid
  List<ServiceCommandDescriptor> getCommands();

  @Valid
  GracefulStopDescriptor getStopRunner();

  @UniqueField("name")
  @Valid
  List<RoleDescriptor> getRoles();

  @UniqueField.List({
    @UniqueField("name"),
    @UniqueField("configName")
  })
  @Valid
  List<Parameter<?>> getParameters();

  @UniqueField("name")
  @Valid
  List<ServiceDependency> getServiceDependencies();

  @Valid
  @Unstable
  List<DependencyExtension> getDependencyExtensions();

  @Valid
  GatewayDescriptor getGateway();

  @UniqueField("name")
  @Valid
  Set<CreateHdfsDirDescriptor> getHdfsDirs();

  @Valid
  ServiceInitDescriptor getServiceInit();

  @Valid
  ProvidesDfs getProvidesDfs();

  @Valid
  ProvidesKms getProvidesKms();

  /**
   * Whether kerberos authentication is used.
   * <p>
   * A service will require kerberos authentication if any of the following is true:
   * <ol>
   * <li>Any dependency of the service requires kerberos authentication
   * <li>This field returns a value of "true" or "kerberos" (case-insensitive)
   * </ol>
   */
  @AvailableSubstitutions(type={PARAMETERS})
  public String getKerberos();

  /**
   * List of external kerberos principals used by the service.
   * Cloudera Manager will not manage these principals, but this can be
   * used to refer to any external principals in configuration.
   */
  @Valid
  @UniqueField("name")
  List<KerberosPrincipalDescriptor> getExternalKerberosPrincipals();

  /**
   * Optional. If set, gets the license feature that all roles of this service
   * will require. If not set, then roles will not require any license feature.
   * Not intended for use outside of Cloudera, as License Features are not part
   * of any documentation or stable API.
   */
  @Unstable
  String getLicenseFeature();

  /**
   * Optional. Configure which users can perform various actions on this
   * service. Not intended for use outside of Cloudera, as Authorities are not
   * part of any documentation or stable API.
   */
  @Unstable
  AuthorityDescriptor getAuthorities();

  /**
   * If service supports rolling restart, the steps can be specified using this.
   */
  RollingRestartDescriptor getRollingRestart();
}
