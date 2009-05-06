!> \file
!> $Id: FiniteElasticityExample.f90 20 2007-05-28 20:22:52Z cpb $
!> \author Chris Bradley
!> \brief This is an example program to solve a finite elasticity equation using openCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is openCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s): Kumar Mithraratne
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> Main program
PROGRAM FINITEELASTICITYEXAMPLE

  USE BASE_ROUTINES		   
  USE BASIS_ROUTINES		   
  USE CMISS			   
  USE CMISS_MPI 		   
  USE CMISS_PETSC		   
  USE COMP_ENVIRONMENT		   
  USE CONSTANTS 		   
  USE CONTROL_LOOP_ROUTINES	   
  USE COORDINATE_ROUTINES	   
  USE DISTRIBUTED_MATRIX_VECTOR    
  USE DOMAIN_MAPPINGS		   
  USE EQUATIONS_ROUTINES	   
  USE EQUATIONS_SET_CONSTANTS	   
  USE EQUATIONS_SET_ROUTINES	   
  USE FIELD_ROUTINES		   
  USE FIELD_IO_ROUTINES 
  USE GENERATED_MESH_ROUTINES	   
  USE INPUT_OUTPUT		   
  USE ISO_VARYING_STRING	   
  USE KINDS			   
  USE LISTS			   
  USE MESH_ROUTINES		   
  USE MPI			   
  USE NODE_ROUTINES  		   
  USE PROBLEM_CONSTANTS 	   
  USE PROBLEM_ROUTINES		   
  USE REGION_ROUTINES		   
  USE SOLVER_ROUTINES		   
  USE TIMER			   
  USE TYPES
  USE FINITE_ELASTICITY_ROUTINES !temporary

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Test program parameters

  REAL(DP), PARAMETER :: HEIGHT=1.0_DP
  REAL(DP), PARAMETER :: WIDTH=1.0_DP
  REAL(DP), PARAMETER :: LENGTH=1.0_DP

  !Program types


  !Program variables

  INTEGER(INTG) :: NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS
  INTEGER(INTG) :: NUMBER_COMPUTATIONAL_NODES,NUMBER_OF_DOMAINS,MY_COMPUTATIONAL_NODE_NUMBER,MPI_IERROR
  INTEGER(INTG) :: EQUATIONS_SET_INDEX  
  INTEGER(INTG) :: NEXT_NUMBER
  INTEGER(INTG) :: first_global_dof,first_local_dof,first_local_rank,last_global_dof,last_local_dof,last_local_rank,rank_idx
 
  TYPE(BASIS_TYPE), POINTER :: BASIS
  TYPE(COORDINATE_SYSTEM_TYPE), POINTER :: COORDINATE_SYSTEM
  TYPE(MESH_TYPE), POINTER :: MESH
  TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
  TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
  TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
  TYPE(FIELD_TYPE), POINTER :: GEOMETRIC_FIELD,FIBRE_FIELD,MATERIAL_FIELD,DEPENDENT_FIELD
  TYPE(PROBLEM_TYPE), POINTER :: PROBLEM
  TYPE(REGION_TYPE), POINTER :: REGION
  TYPE(SOLVER_TYPE), POINTER :: SOLVER,LINEAR_SOLVER
  TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
  TYPE(NODES_TYPE), POINTER :: NODES
  TYPE(MESH_ELEMENTS_TYPE), POINTER :: ELEMENTS
  !TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: DISTRIBUTED_VECTOR
  !TYPE(GENERATED_MESH_TYPE), POINTER :: GENERATED_MESH
  !TYPE(DOMAIN_MAPPING_TYPE), POINTER :: DEPENDENT_DOF_MAPPING
        
  LOGICAL :: EXPORT_FIELD,IMPORT_FIELD
  TYPE(VARYING_STRING) :: FILE,METHOD

  REAL(SP) :: START_USER_TIME(1),STOP_USER_TIME(1),START_SYSTEM_TIME(1),STOP_SYSTEM_TIME(1)

#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  !Generic CMISS variables

  INTEGER(INTG) :: ERR
  TYPE(VARYING_STRING) :: ERROR
  INTEGER(INTG) :: DIAG_LEVEL_LIST(5)
  CHARACTER(LEN=MAXSTRLEN) :: DIAG_ROUTINE_LIST(1),TIMING_ROUTINE_LIST(1)

  !local variables
  INTEGER(INTG) :: coordinate_system_user_number,number_of_spatial_coordinates
  INTEGER(INTG) :: region_user_number
  INTEGER(INTG) :: basis_user_number,number_of_xi_coordinates  
  INTEGER(INTG) :: total_number_of_nodes,node_idx,global_node_number  
  INTEGER(INTG) :: mesh_user_number,number_of_mesh_dimensions,number_of_mesh_components
  INTEGER(INTG) :: total_number_of_elements,mesh_component_number
  INTEGER(INTG) :: decomposition_user_number  
  INTEGER(INTG) :: field_geomtery_user_number,field_geometry_number_of_varaiables,field_geometry_number_of_components  
  INTEGER(INTG) :: field_fibre_user_number,field_fibre_number_of_varaiables,field_fibre_number_of_components 
  INTEGER(INTG) :: field_material_user_number,field_material_number_of_varaiables,field_material_number_of_components 
  INTEGER(INTG) :: field_dependent_user_number,field_dependent_number_of_varaiables,field_dependent_number_of_components 
  INTEGER(INTG) :: equation_set_user_number
  INTEGER(INTG) :: problem_user_number     
  INTEGER(INTG) :: dof_idx,unfixed_dofs,total_no_dofs   
  REAL(DP) :: VALUE
  
#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

  !Intialise cmiss
  CALL CMISS_INITIALISE(ERR,ERROR,*999)

  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***PROGRAM STARTING********************",ERR,ERROR,*999)

  !Set all diganostic levels on for testing
  DIAG_LEVEL_LIST(1)=1
  DIAG_LEVEL_LIST(2)=2
  DIAG_LEVEL_LIST(3)=3
  DIAG_LEVEL_LIST(4)=4
  DIAG_LEVEL_LIST(5)=5

  TIMING_ROUTINE_LIST(1)="PROBLEM_FINITE_ELEMENT_CALCULATE"

  !Calculate the start times
  CALL CPU_TIMER(USER_CPU,START_USER_TIME,ERR,ERROR,*999)
  CALL CPU_TIMER(SYSTEM_CPU,START_SYSTEM_TIME,ERR,ERROR,*999)

  !Get the number of computational nodes
  NUMBER_COMPUTATIONAL_NODES=COMPUTATIONAL_NODES_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999
  !Get my computational node number
  MY_COMPUTATIONAL_NODE_NUMBER=COMPUTATIONAL_NODE_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999

  !Read in the number of elements in the X & Y directions, and the number of partitions on the master node (number 0)
  !IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
  !  WRITE(*,'("Enter the number of elements in the X direction :")')
  !  READ(*,*) number_global_x_elements
  !  WRITE(*,'("Enter the number of elements in the Y direction :")')
  !  READ(*,*) number_global_y_elements
  !  WRITE(*,'("Enter the number of elements in the Z direction :")')
  !  READ(*,*) number_global_z_elements
  !  WRITE(*,'("Enter the number of domains :")')
  !  READ(*,*) number_of_domains
  !ENDIF
  
   number_global_x_elements=1
   number_global_y_elements=1
   number_global_z_elements=1   
   number_of_domains=1
   
  !Broadcast the number of elements in the X,Y and Z directions and the number of partitions to the other computational nodes
  CALL MPI_BCAST(number_global_x_elements,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
  CALL MPI_BCAST(number_global_y_elements,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
  CALL MPI_BCAST(number_global_z_elements,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
  CALL MPI_BCAST(NUMBER_OF_DOMAINS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
  
  !Create a CS - default is 3D rectangular cartesian CS with 0,0,0 as origin
  coordinate_system_user_number=1
  number_of_spatial_coordinates=3
  CALL COORDINATE_SYSTEM_CREATE_START(coordinate_system_user_number,COORDINATE_SYSTEM,ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_TYPE_SET(coordinate_system_user_number,COORDINATE_RECTANGULAR_CARTESIAN_TYPE,ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_DIMENSION_SET(COORDINATE_SYSTEM,number_of_spatial_coordinates,ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_ORIGIN_SET(coordinate_system_user_number,(/0.0_DP,0.0_DP,0.0_DP/),ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_CREATE_FINISH(COORDINATE_SYSTEM,ERR,ERROR,*999)

  !Create a region and assign the CS to the region
  region_user_number=1
  CALL REGION_CREATE_START(region_user_number,REGION,ERR,ERROR,*999)
  CALL REGION_COORDINATE_SYSTEM_SET(REGION,COORDINATE_SYSTEM,ERR,ERROR,*999)
  CALL REGION_CREATE_FINISH(REGION,ERR,ERROR,*999)

  !Define basis function - tri-linear Lagrange  
  basis_user_number=1 
  number_of_xi_coordinates=3   
  CALL BASIS_CREATE_START(basis_user_number,BASIS,ERR,ERROR,*999) 
  CALL BASIS_TYPE_SET(basis_user_number,BASIS_LAGRANGE_HERMITE_TP_TYPE,ERR,ERROR,*999)
  CALL BASIS_NUMBER_OF_XI_SET(BASIS,number_of_xi_coordinates,ERR,ERROR,*999)
  CALL BASIS_INTERPOLATION_XI_SET(basis_user_number,(/BASIS_LINEAR_LAGRANGE_INTERPOLATION, &
    & BASIS_LINEAR_LAGRANGE_INTERPOLATION,BASIS_LINEAR_LAGRANGE_INTERPOLATION/),ERR,ERROR,*999)
  CALL BASIS_QUADRATURE_NUMBER_OF_GAUSS_XI_SET(basis_user_number, &
    & (/BASIS_MID_QUADRATURE_SCHEME,BASIS_MID_QUADRATURE_SCHEME,BASIS_MID_QUADRATURE_SCHEME/),ERR,ERROR,*999)  
  CALL BASIS_CREATE_FINISH(BASIS,ERR,ERROR,*999)
  
  !Create nodes
  total_number_of_nodes=8
  CALL NODES_CREATE_START(total_number_of_nodes,REGION,NODES,ERR,ERROR,*999)
  DO node_idx=1,total_number_of_nodes
    CALL NODE_INITIAL_POSITION_SET(node_idx,(/0.0_DP,0.0_DP,0.0_DP/),NODES,ERR,ERROR,*999)
  ENDDO
  CALL NODES_CREATE_FINISH(REGION,ERR,ERROR,*999)

  mesh_user_number=1
  number_of_mesh_dimensions=3
  number_of_mesh_components=1
  total_number_of_elements=1  
  CALL MESH_CREATE_START(mesh_user_number,REGION,number_of_mesh_dimensions,MESH,ERR,ERROR,*999)    
  
  CALL MESH_NUMBER_OF_COMPONENTS_SET(mesh_user_number,REGION,number_of_mesh_components,ERR,ERROR,*999) 
  CALL MESH_NUMBER_OF_ELEMENTS_SET(MESH,total_number_of_elements,ERR,ERROR,*999)  
  
  mesh_component_number=1 
  CALL MESH_TOPOLOGY_ELEMENTS_CREATE_START(MESH,mesh_component_number,BASIS,ELEMENTS,ERR,ERROR,*999)
  CALL MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET(1,ELEMENTS,(/1,2,3,4,5,6,7,8/),ERR,ERROR,*999)
  CALL MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(MESH,mesh_component_number,ERR,ERROR,*999)
        
  CALL MESH_CREATE_FINISH(REGION,MESH,ERR,ERROR,*999) 

  !Create a decomposition
  decomposition_user_number=1
  CALL DECOMPOSITION_CREATE_START(decomposition_user_number,MESH,DECOMPOSITION,ERR,ERROR,*999)
  CALL DECOMPOSITION_TYPE_SET(decomposition,DECOMPOSITION_CALCULATED_TYPE,ERR,ERROR,*999)
  CALL DECOMPOSITION_NUMBER_OF_DOMAINS_SET(DECOMPOSITION,number_of_domains,ERR,ERROR,*999)
  CALL DECOMPOSITION_CREATE_FINISH(MESH,DECOMPOSITION,ERR,ERROR,*999)
  
  !Create a field to put the geometry (defualt is geometry)
  field_geomtery_user_number=1  
  field_geometry_number_of_varaiables=1
  field_geometry_number_of_components=3  
  CALL FIELD_CREATE_START(field_geomtery_user_number,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
  CALL FIELD_MESH_DECOMPOSITION_SET(GEOMETRIC_FIELD,DECOMPOSITION,ERR,ERROR,*999)
  CALL FIELD_TYPE_SET(field_geomtery_user_number,REGION,FIELD_GEOMETRIC_TYPE,ERR,ERROR,*999)  
  CALL FIELD_NUMBER_OF_VARIABLES_SET(field_geomtery_user_number,REGION,field_geometry_number_of_varaiables,ERR,ERROR,*999)
  CALL FIELD_NUMBER_OF_COMPONENTS_SET(field_geomtery_user_number,REGION,field_geometry_number_of_components,ERR,ERROR,*999)  
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_geomtery_user_number,1,1,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_geomtery_user_number,1,2,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_geomtery_user_number,1,3,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)

  !node 1
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,1,1,1,0.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,1,2,1,0.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,1,3,1,0.0_DP,ERR,ERROR,*999)    
  !node 2
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,2,1,1,1.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,2,2,1,0.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,2,3,1,0.0_DP,ERR,ERROR,*999)    
  !node 3
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,3,1,1,0.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,3,2,1,1.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,3,3,1,0.0_DP,ERR,ERROR,*999)    
  !node 4
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,4,1,1,1.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,4,2,1,1.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,4,3,1,0.0_DP,ERR,ERROR,*999)    
  !node 5
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,5,1,1,0.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,5,2,1,0.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,5,3,1,1.0_DP,ERR,ERROR,*999)    
  !node 6
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,6,1,1,1.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,6,2,1,0.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,6,3,1,1.0_DP,ERR,ERROR,*999)    
  !node 7
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,7,1,1,0.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,7,2,1,1.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,7,3,1,1.0_DP,ERR,ERROR,*999)    
  !node 8
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,8,1,1,1.0_DP,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,8,2,1,1.0_DP,ERR,ERROR,*999)  
  CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_VALUES_SET_TYPE,1,8,3,1,1.0_DP,ERR,ERROR,*999)    
  
  !Create a fibre field and attach it to the geometric field  
  field_fibre_user_number=2  
  field_fibre_number_of_varaiables=1
  field_fibre_number_of_components=3  
  CALL FIELD_CREATE_START(field_fibre_user_number,REGION,FIBRE_FIELD,ERR,ERROR,*999)
  CALL FIELD_TYPE_SET(field_fibre_user_number,REGION,FIELD_FIBRE_TYPE,ERR,ERROR,*999)
  CALL FIELD_MESH_DECOMPOSITION_SET(FIBRE_FIELD,DECOMPOSITION,ERR,ERROR,*999)        
  CALL FIELD_GEOMETRIC_FIELD_SET(field_fibre_user_number,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
  CALL FIELD_NUMBER_OF_VARIABLES_SET(field_fibre_user_number,REGION,field_fibre_number_of_varaiables,ERR,ERROR,*999)
  CALL FIELD_NUMBER_OF_COMPONENTS_SET(field_fibre_user_number,REGION,field_fibre_number_of_components,ERR,ERROR,*999)  
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_fibre_user_number,1,1,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_fibre_user_number,1,2,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_fibre_user_number,1,3,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(REGION,FIBRE_FIELD,ERR,ERROR,*999)
     
  !Create a material field and attach it to the geometric field  
  field_material_user_number=3  
  field_material_number_of_varaiables=1
  field_material_number_of_components=2  
  CALL FIELD_CREATE_START(field_material_user_number,REGION,MATERIAL_FIELD,ERR,ERROR,*999)
  CALL FIELD_TYPE_SET(field_material_user_number,REGION,FIELD_MATERIAL_TYPE,ERR,ERROR,*999)
  CALL FIELD_MESH_DECOMPOSITION_SET(MATERIAL_FIELD,DECOMPOSITION,ERR,ERROR,*999)        
  CALL FIELD_GEOMETRIC_FIELD_SET(field_material_user_number,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
  CALL FIELD_NUMBER_OF_VARIABLES_SET(field_material_user_number,REGION,field_material_number_of_varaiables,ERR,ERROR,*999)
  CALL FIELD_NUMBER_OF_COMPONENTS_SET(field_material_user_number,REGION,field_material_number_of_components,ERR,ERROR,*999)  
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_material_user_number,1,1,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_material_user_number,1,2,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(REGION,MATERIAL_FIELD,ERR,ERROR,*999)

  !Set Mooney-Rivlin constants c10 and c01 to 2.0 and 3.0 respectively at each node.
  total_number_of_nodes=mesh%TOPOLOGY(mesh_component_number)%PTR%NODES%NUMBER_OF_NODES
  DO node_idx=1,total_number_of_nodes
    global_node_number=MESH%TOPOLOGY(mesh_component_number)%PTR%NODES%NODES(node_idx)%GLOBAL_NUMBER
    CALL FIELD_PARAMETER_SET_UPDATE_NODE(MATERIAL_FIELD,FIELD_VALUES_SET_TYPE,1,node_idx,1,1,2.0_DP,ERR,ERROR,*999)
    CALL FIELD_PARAMETER_SET_UPDATE_NODE(MATERIAL_FIELD,FIELD_VALUES_SET_TYPE,1,node_idx,2,1,3.0_DP,ERR,ERROR,*999)
  ENDDO
  
  !Create a dependent field with two variables and four components
  field_dependent_user_number=4  
  field_dependent_number_of_varaiables=2
  field_dependent_number_of_components=4    
  CALL FIELD_CREATE_START(field_dependent_user_number,REGION,DEPENDENT_FIELD,ERR,ERROR,*999)
  CALL FIELD_TYPE_SET(field_dependent_user_number,REGION,FIELD_GENERAL_TYPE,ERR,ERROR,*999)  
  CALL FIELD_MESH_DECOMPOSITION_SET(DEPENDENT_FIELD,DECOMPOSITION,ERR,ERROR,*999)
  CALL FIELD_GEOMETRIC_FIELD_SET(field_dependent_user_number,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999) 
  CALL FIELD_DEPENDENT_TYPE_SET(field_dependent_user_number,REGION,FIELD_DEPENDENT_TYPE,ERR,ERROR,*999) 
  CALL FIELD_NUMBER_OF_VARIABLES_SET(field_dependent_user_number,REGION,field_dependent_number_of_varaiables,ERR,ERROR,*999)
  CALL FIELD_NUMBER_OF_COMPONENTS_SET(field_dependent_user_number,REGION,field_dependent_number_of_components,ERR,ERROR,*999)    
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_dependent_user_number,1,1,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_dependent_user_number,1,2,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_dependent_user_number,1,3,REGION,mesh_component_number,ERR,ERROR,*999)  
  CALL FIELD_COMPONENT_INTERPOLATION_SET(DEPENDENT_FIELD,1,4,FIELD_ELEMENT_BASED_INTERPOLATION,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_dependent_user_number,2,1,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_dependent_user_number,2,2,REGION,mesh_component_number,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_MESH_COMPONENT_SET(field_dependent_user_number,2,3,REGION,mesh_component_number,ERR,ERROR,*999)  
  CALL FIELD_COMPONENT_INTERPOLATION_SET(DEPENDENT_FIELD,2,4,FIELD_ELEMENT_BASED_INTERPOLATION,ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(REGION,DEPENDENT_FIELD,ERR,ERROR,*999)  
    
  !Create the equations_set
  equation_set_user_number=1
  CALL EQUATIONS_SET_CREATE_START(equation_set_user_number,REGION,GEOMETRIC_FIELD,EQUATIONS_SET,ERR,ERROR,*999)
  CALL EQUATIONS_SET_SPECIFICATION_SET(EQUATIONS_SET,EQUATIONS_SET_ELASTICITY_CLASS, &
    & EQUATIONS_SET_FINITE_ELASTICITY_TYPE,EQUATIONS_SET_NO_SUBTYPE,ERR,ERROR,*999)
  CALL EQUATIONS_SET_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

  CALL EQUATIONS_SET_DEPENDENT_CREATE_START(equations_set,ERR,ERROR,*999) 
  CALL EQUATIONS_SET_DEPENDENT_CREATE_FINISH(equations_set,ERR,ERROR,*999)

  CALL EQUATIONS_SET_MATERIALS_CREATE_START(EQUATIONS_SET,ERR,ERROR,*999)  
  !CALL EQUATIONS_SET_MATERIALS_COMPONENT_INTERPOLATION_SET(EQUATIONS_SET,1,1,ERR,ERROR,*999)
  !CALL EQUATIONS_SET_MATERIALS_COMPONENT_MESH_COMPONENT_SET(EQUATIONS_SET,COMPONENT_NUMBER,MESH_COMPONENT_NUMBER,ERR,ERROR,*
  CALL EQUATIONS_SET_MATERIALS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

  EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD=>GEOMETRIC_FIELD 
  EQUATIONS_SET%GEOMETRY%FIBRE_FIELD=>FIBRE_FIELD   
  EQUATIONS_SET%MATERIALS%MATERIALS_FIELD=>MATERIAL_FIELD
  EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD=>DEPENDENT_FIELD 
  
  !Prescribe boundary conditions - This must be undeformed + displacement bcs
  CALL EQUATIONS_SET_FIXED_CONDITIONS_CREATE_START(EQUATIONS_SET,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,1,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,2,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.1_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,3,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,4,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.1_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,5,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,6,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.1_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,7,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,8,1,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.2_DP,ERR,ERROR,*999)    
    
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,1,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,2,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)    
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,3,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,4,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,5,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,6,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)        
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,7,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,8,2,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)   
             
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,1,3,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,3,3,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,5,3,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_SET_NODE(EQUATIONS_SET,FIELD_BOUNDARY_CONDITIONS_SET_TYPE,1,7,3,1, &
    & EQUATIONS_SET_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL EQUATIONS_SET_FIXED_CONDITIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

!  CALL FIELD_PARAMETER_SET_ADD_NODE(FIELD,FIELD_SET_TYPE,DERIVATIVE_NUMBER,NODE_NUMBER,COMPONENT_NUMBER,  &
!    & VARIABLE_NUMBER,VALUE,ERR,ERROR,*999)
!  CALL FIELD_PARAMETER_SETS_COPY(FIELD,FIELD_FROM_SET_TYPE,FIELD_TO_SET_TYPE,ERR,ERROR,*999)
!  CALL FIELD_PARAMETER_SET_DATA_GET(GEOMETRIC_FIELD,1,PARAMETERS,ERR,ERROR,*999)  
!  CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,1,1,ERR,ERROR,*999)  
!  CALL FIELD_PARAMETER_SET_VECTOR_GET(GEOMETRIC_FIELD,1,DISTRIBUTED_VECTOR,ERR,ERROR,*999)    

  !Create the equations set equations
  NULLIFY(EQUATIONS)
  CALL EQUATIONS_SET_EQUATIONS_CREATE_START(EQUATIONS_SET,ERR,ERROR,*999)
  CALL EQUATIONS_SET_EQUATIONS_GET(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*999)
  CALL EQUATIONS_SPARSITY_TYPE_SET(EQUATIONS,EQUATIONS_SPARSE_MATRICES,ERR,ERROR,*999)
  CALL EQUATIONS_OUTPUT_TYPE_SET(EQUATIONS,EQUATIONS_NO_OUTPUT,ERR,ERROR,*999)
  CALL EQUATIONS_SET_EQUATIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)   
                                                                             	   								 
  !Define the problem
  NULLIFY(PROBLEM)
  problem_user_number=1
  CALL PROBLEM_CREATE_START(problem_user_number,PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_SPECIFICATION_SET(PROBLEM,PROBLEM_ELASTICITY_CLASS,PROBLEM_FINITE_ELASTICITY_TYPE, &
    & PROBLEM_NO_SUBTYPE,ERR,ERROR,*999)
  CALL PROBLEM_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)
  
  !Create the problem control loop
  CALL PROBLEM_CONTROL_LOOP_CREATE_START(PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_CONTROL_LOOP_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem solvers
  NULLIFY(SOLVER)
  NULLIFY(LINEAR_SOLVER)
  CALL PROBLEM_SOLVERS_CREATE_START(PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_SOLVER_GET(PROBLEM,CONTROL_LOOP_NODE,1,SOLVER,ERR,ERROR,*999)
  CALL SOLVER_OUTPUT_TYPE_SET(SOLVER,SOLVER_PROGRESS_OUTPUT,ERR,ERROR,*999)
  !CALL SOLVER_OUTPUT_TYPE_SET(SOLVER,SOLVER_MATRIX_OUTPUT,ERR,ERROR,*999)
  CALL SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET(SOLVER,SOLVER_NEWTON_JACOBIAN_FD_CALCULATED,ERR,ERROR,*999)      
  !CALL SOLVER_NEWTON_LINESEARCH_ALPHA_SET(SOLVER,0.1_DP,ERR,ERROR,*999)   
  CALL PROBLEM_SOLVERS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem solver equations
  NULLIFY(SOLVER)
  NULLIFY(SOLVER_EQUATIONS)
  CALL PROBLEM_SOLVER_EQUATIONS_CREATE_START(PROBLEM,ERR,ERROR,*999)   
  CALL PROBLEM_SOLVER_GET(PROBLEM,CONTROL_LOOP_NODE,1,SOLVER,ERR,ERROR,*999)
  CALL SOLVER_SOLVER_EQUATIONS_GET(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*999)
  CALL SOLVER_EQUATIONS_SPARSITY_TYPE_SET(SOLVER_EQUATIONS,SOLVER_SPARSE_MATRICES,ERR,ERROR,*999)
  CALL PROBLEM_SOLVER_EQUATIONS_EQUATIONS_SET_ADD(PROBLEM,CONTROL_LOOP_NODE,1,EQUATIONS_SET,EQUATIONS_SET_INDEX,ERR,ERROR,*999)
  CALL PROBLEM_SOLVER_EQUATIONS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !CALL VecView(PROBLEM%PROBLEMS%PROBLEMS(1)%PTR%CONTROL_LOOP%SOLVERS%SOLVERS(1)%PTR%SOLVER_EQUATIONS%  &
  ! & SOLVER_MATRICES%RHS_VECTOR%PETSC%VECTOR%VEC,PETSC_VIEWER_STDOUT_SELF,ERR)
  !CALL PETSC_ERRORHANDLING_SET_OFF(ERR,ERROR,*999)
  
  CALL FINITE_ELASTICITY_INITIAL_GUESS(EQUATIONS_SET,ERR,ERROR,*999)  !temporary 
  unfixed_dofs=0
  total_no_dofs=PROBLEM%CONTROL_LOOP%SOLVERS%SOLVERS(1)%PTR%SOLVER_EQUATIONS%SOLVER_MAPPING%EQUATIONS_SETS(1)%PTR%  &
    & FIXED_CONDITIONS%BOUNDARY_CONDITIONS%CMISS%N/2
  DO dof_idx=1,total_no_dofs
    IF (PROBLEM%CONTROL_LOOP%SOLVERS%SOLVERS(1)%PTR%SOLVER_EQUATIONS%SOLVER_MAPPING%EQUATIONS_SETS(1)% &
      PTR%FIXED_CONDITIONS%BOUNDARY_CONDITIONS%CMISS%DATA_INTG(dof_idx)==0) THEN
      VALUE=PROBLEM%CONTROL_LOOP%SOLVERS%SOLVERS(1)%PTR%SOLVER_EQUATIONS%SOLVER_MAPPING%EQUATIONS_SETS(1)%  &
        & PTR%DEPENDENT%DEPENDENT_FIELD%PARAMETER_SETS%PARAMETER_SETS(1)%PTR%PARAMETERS%CMISS%DATA_DP(dof_idx)
      CALL VecSetValues(PROBLEM%PROBLEMS%PROBLEMS(1)%PTR%CONTROL_LOOP%SOLVERS%SOLVERS(1)%PTR%SOLVER_EQUATIONS%SOLVER_MATRICES% &
        & MATRICES(1)%PTR%SOLVER_VECTOR%PETSC%VECTOR,1,unfixed_dofs,VALUE,PETSC_INSERT_VALUES,ERR)  
        unfixed_dofs=unfixed_dofs+1
    ENDIF    
  ENDDO
  CALL VecView(PROBLEM%PROBLEMS%PROBLEMS(1)%PTR%CONTROL_LOOP%SOLVERS%SOLVERS(1)%PTR%SOLVER_EQUATIONS%SOLVER_MATRICES% &
    & MATRICES(1)%PTR%SOLVER_VECTOR%PETSC%VECTOR,PETSC_VIEWER_STDOUT_SELF,ERR)


  CALL PROBLEM_SOLVE(PROBLEM,ERR,ERROR,*999)

  !Output solution
  DO dof_idx=1,total_no_dofs
    WRITE(6,'(2x,f9.6)') DEPENDENT_FIELD%PARAMETER_SETS%PARAMETER_SETS(1)%PTR%PARAMETERS%CMISS%DATA_DP(dof_idx)
  ENDDO

  !Calculate the stop time and write out the elapsed user and system times
  CALL CPU_TIMER(USER_CPU,STOP_USER_TIME,ERR,ERROR,*999)
  CALL CPU_TIMER(SYSTEM_CPU,STOP_SYSTEM_TIME,ERR,ERROR,*999)

  WRITE(*,'(" USER TIME   = ",f12.8)') STOP_USER_TIME(1)-START_USER_TIME(1)
  WRITE(*,'(" SYSTEM TIME = ",f12.8)') STOP_SYSTEM_TIME(1)-START_SYSTEM_TIME(1)

  CALL CMISS_FINALISE(ERR,ERROR,*999)

  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***PROGRAM SUCCESSFULLY COMPLETED******",ERR,ERROR,*999)
  
  STOP
999 CALL CMISS_WRITE_ERROR(ERR,ERROR)
  STOP

END PROGRAM FINITEELASTICITYEXAMPLE
