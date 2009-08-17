!> \file
!> $Id: AnalyticLaplaceExample.f90 20 2007-05-28 20:22:52Z cpb $
!> \author Chris Bradley
!> \brief This is an example program to solve an Analytic Laplace equation using openCMISS calls.
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
!> Contributor(s):
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

!> \example ClassicalField/AnalyticLaplace/src/AnalyticLaplaceExample.f90
!! Example illustrating the use of openCMISS to solve the Laplace problem and check with its Analytic Solution.
!! 
!! \par Latest Builds:
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/ClassicalField/AnalyticLaplace/build-intel'>Linux Intel Build</a>
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/ClassicalField/AnalyticLaplace/build-gnu'>Linux GNU Build</a>
!< 

!> Main program
PROGRAM ANALYTICLAPLACEEXAMPLE

  USE ANALYTIC_ANALYSIS_ROUTINES
  USE BASE_ROUTINES
  USE BASIS_ROUTINES
  USE BOUNDARY_CONDITIONS_ROUTINES
  USE CMISS
  USE CMISS_MPI
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
  USE LAPLACE_EQUATIONS_ROUTINES
  USE LISTS
  USE MESH_ROUTINES
  USE MPI
  USE PROBLEM_CONSTANTS
  USE PROBLEM_ROUTINES
  USE REGION_ROUTINES
  USE SOLVER_ROUTINES
  USE STRINGS
  USE TEST_FRAMEWORK_ROUTINES
  USE TIMER
  USE TYPES

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Test program parameters

  REAL(DP), PARAMETER :: ORIGIN(2)=(/-PI/2, -PI/2/)
  REAL(DP), PARAMETER :: HEIGHT=PI
  REAL(DP), PARAMETER :: WIDTH=PI
  REAL(DP), PARAMETER :: LENGTH=PI

  !Program types

  !Program variables

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
  
  !Set all diganostic levels on for testing
  DIAG_LEVEL_LIST(1)=1
  DIAG_LEVEL_LIST(2)=2
  DIAG_LEVEL_LIST(3)=3
  DIAG_LEVEL_LIST(4)=4
  DIAG_LEVEL_LIST(5)=5
  
  TIMING_ROUTINE_LIST(1)="PROBLEM_FINITE_ELEMENT_CALCULATE"
  
  CALL ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_CONVERGENCE(2,6,2,ERR,ERROR,*999)
  CALL ANALYTICLAPLACE_TESTCASE_BICUBIC_HERMITE_CONVERGENCE(2,10,2,ERR,ERROR,*999)
  CALL ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_EXPORT(2,2,0,ERR,ERROR,*999)

  CALL CMISS_FINALISE(ERR,ERROR,*999)

  STOP
999 CALL CMISS_WRITE_ERROR(ERR,ERROR)
  STOP 1
  
CONTAINS

  !
  !================================================================================================================================
  !  
    !>Check if the convergence of bilinear langrange interpolation is expected.
  SUBROUTINE ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_EXPORT(NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS, &
    & NUMBER_GLOBAL_Z_ELEMENTS,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: NUMBER_GLOBAL_X_ELEMENTS !<initial number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_GLOBAL_Y_ELEMENTS !<final number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_GLOBAL_Z_ELEMENTS !<increment interval number of elements per axis
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(FIELD_TYPE), POINTER :: FIELD

    CALL ENTERS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_EXPORT",ERR,ERROR,*999)

    CALL ANALYTICLAPLACE_GENERIC(NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS,1,FIELD,ERR, &
      & ERROR,*999)

    CALL ANALYTIC_ANALYSIS_OUTPUT(FIELD,"AnalyticLaplaceBilinear",ERR,ERROR,*999)
    
    CALL EXITS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_EXPORT")
    RETURN
999 CALL ERRORS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_EXPORT",ERR,ERROR)
    CALL EXITS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_EXPORT")
    RETURN 1
  END SUBROUTINE ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_EXPORT
  
  !
  !================================================================================================================================
  !   
  
  !>Check if the convergence of bilinear langrange interpolation is expected.
  SUBROUTINE ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_CONVERGENCE(NUMBER_OF_ELEMENTS_XI_START,NUMBER_OF_ELEMENTS_XI_END, &
    & NUMBER_OF_ELEMENTS_XI_INTERVAL,ERR,ERROR,*)
  
    !Argument variables 
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_START !<initial number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_END !<final number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_INTERVAL !<increment interval number of elements per axis
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    REAL(DP) :: VALUE
    REAL(DP), ALLOCATABLE :: X_VALUES(:),Y_VALUES(:)
    TYPE(VARYING_STRING) :: ERROR_MESSAGE
    
    CALL ENTERS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_CONVERGENCE",ERR,ERROR,*999)
    
    CALL ANALYTICLAPLACE_GENERIC_CONVERGENCE(NUMBER_OF_ELEMENTS_XI_START,NUMBER_OF_ELEMENTS_XI_END, &
      & NUMBER_OF_ELEMENTS_XI_INTERVAL,1,X_VALUES,Y_VALUES,ERR,ERROR,*999)
    
    CALL TEST_FRAMEWORK_GRADIENT_VALUE_GET(X_VALUES,Y_VALUES,VALUE,ERR,ERROR,*999)
    ERROR_MESSAGE="The convergence of the bilinear Laplace problem should be between 1.5 to 2.5, but it is "//NUMBER_TO_VSTRING( &
      & VALUE,"*",ERR,ERROR)//"."
    CALL TEST_FRAMEWORK_ASSERT_EQUALS(2.0_DP,VALUE,0.5_DP,ERROR_MESSAGE,ERR,ERROR,*999)
    
    WRITE(*,'(A)') "Analytic Laplace Example Testcase1 - bilinear lagrange is successfully completed."
    
    CALL EXITS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_CONVERGENCE")
    RETURN
999 CALL ERRORS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_CONVERGENCE",ERR,ERROR)
    CALL EXITS("ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_CONVERGENCE")
    RETURN 1
  END SUBROUTINE ANALYTICLAPLACE_TESTCASE_BILINEAR_LAGRANGE_CONVERGENCE
  
  !
  !================================================================================================================================
  !   
  
  !>Check if the convergence of bilinear langrange interpolation is expected.
  SUBROUTINE ANALYTICLAPLACE_TESTCASE_BICUBIC_HERMITE_CONVERGENCE(NUMBER_OF_ELEMENTS_XI_START,NUMBER_OF_ELEMENTS_XI_END, &
    & NUMBER_OF_ELEMENTS_XI_INTERVAL,ERR,ERROR,*)
  
    !Argument variables 
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_START !<initial number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_END !<final number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_INTERVAL !<increment interval number of elements per axis
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    REAL(DP) :: VALUE
    REAL(DP), ALLOCATABLE :: X_VALUES(:),Y_VALUES(:)
    TYPE(VARYING_STRING) :: ERROR_MESSAGE
    
    CALL ENTERS("ANALYTICLAPLACE_TESTCASE_BICUBIC_HERMITE_CONVERGENCE",ERR,ERROR,*999)

    CALL ANALYTICLAPLACE_GENERIC_CONVERGENCE(NUMBER_OF_ELEMENTS_XI_START,NUMBER_OF_ELEMENTS_XI_END, &
      & NUMBER_OF_ELEMENTS_XI_INTERVAL,3,X_VALUES,Y_VALUES,ERR,ERROR,*999)
    
    CALL TEST_FRAMEWORK_GRADIENT_VALUE_GET(X_VALUES,Y_VALUES,VALUE,ERR,ERROR,*999)
    ERROR_MESSAGE="The convergence of the bicubic Laplace problem should be between 3.0 to 5.0, but it is "//NUMBER_TO_VSTRING( &
      & VALUE,"*",ERR,ERROR)//"."
    CALL TEST_FRAMEWORK_ASSERT_EQUALS(4.0_DP,VALUE,1.0_DP,ERROR_MESSAGE,ERR,ERROR,*999)
    
    WRITE(*,'(A)') "Analytic Laplace Example Testcase2 - bicubic Hermite is successfully completed."
    
    CALL EXITS("ANALYTICLAPLACE_TESTCASE_BICUBIC_HERMITE_CONVERGENCE")
    RETURN
999 CALL ERRORS("ANALYTICLAPLACE_TESTCASE_BICUBIC_HERMITE_CONVERGENCE",ERR,ERROR)
    CALL EXITS("ANALYTICLAPLACE_TESTCASE_BICUBIC_HERMITE_CONVERGENCE")
    RETURN 1
  END SUBROUTINE ANALYTICLAPLACE_TESTCASE_BICUBIC_HERMITE_CONVERGENCE
  
  !
  !================================================================================================================================
  !   
  
  !>Check if the convergence of bilinear langrange interpolation is expected.
  SUBROUTINE ANALYTICLAPLACE_GENERIC_CONVERGENCE(NUMBER_OF_ELEMENTS_XI_START,NUMBER_OF_ELEMENTS_XI_END, &
    & NUMBER_OF_ELEMENTS_XI_INTERVAL,INTERPOLATION_SPECIFICATIONS,X_VALUES,Y_VALUES,ERR,ERROR,*)
  
    !Argument variables 
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_START !<initial number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_END !<final number of elements per axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS_XI_INTERVAL !<increment interval number of elements per axis
    INTEGER(INTG), INTENT(IN) :: INTERPOLATION_SPECIFICATIONS !<interpolation specifications
    REAL(DP), ALLOCATABLE :: X_VALUES(:),Y_VALUES(:)
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    REAL(DP) :: VALUE
    
    INTEGER(INTG) :: i
    TYPE(FIELD_TYPE), POINTER :: FIELD
    
    CALL ENTERS("ANALYTICLAPLACE_GENERIC_CONVERGENCE",ERR,ERROR,*999)
    
    ALLOCATE(X_VALUES((NUMBER_OF_ELEMENTS_XI_END-NUMBER_OF_ELEMENTS_XI_START)/NUMBER_OF_ELEMENTS_XI_INTERVAL+1),STAT=ERR)
    ALLOCATE(Y_VALUES((NUMBER_OF_ELEMENTS_XI_END-NUMBER_OF_ELEMENTS_XI_START)/NUMBER_OF_ELEMENTS_XI_INTERVAL+1),STAT=ERR)

    DO i = NUMBER_OF_ELEMENTS_XI_START,NUMBER_OF_ELEMENTS_XI_END,NUMBER_OF_ELEMENTS_XI_INTERVAL
      
      CALL ANALYTICLAPLACE_GENERIC(i,i,0,INTERPOLATION_SPECIFICATIONS,FIELD,ERR,ERROR,*999)
      CALL ANALYTIC_ANALYSIS_NODE_ABSOLUTE_ERROR_GET(FIELD,1,(i+1)**2/2+1,1,1,VALUE,ERR,ERROR,*999)
      Y_VALUES((i-NUMBER_OF_ELEMENTS_XI_START)/NUMBER_OF_ELEMENTS_XI_INTERVAL+1)=log10(VALUE)
      X_VALUES((i-NUMBER_OF_ELEMENTS_XI_START)/NUMBER_OF_ELEMENTS_XI_INTERVAL+1)=log10(HEIGHT/i)
   
    ENDDO
    
    CALL EXITS("ANALYTICLAPLACE_GENERIC_CONVERGENCE")
    RETURN
999 CALL ERRORS("ANALYTICLAPLACE_GENERIC_CONVERGENCE",ERR,ERROR)
    CALL EXITS("ANALYTICLAPLACE_GENERIC_CONVERGENCE")
    RETURN 1
  END SUBROUTINE ANALYTICLAPLACE_GENERIC_CONVERGENCE
  
  
  !
  !================================================================================================================================
  !   
    
  SUBROUTINE ANALYTICLAPLACE_GENERIC(NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS, &
    & INTERPOLATION_SPECIFICATIONS,DEPENDENT_FIELD,ERR,ERROR,*)
    !Argument variables 
    INTEGER(INTG), INTENT(IN) :: NUMBER_GLOBAL_X_ELEMENTS !<number of elements on x axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_GLOBAL_Y_ELEMENTS !<number of elements on y axis
    INTEGER(INTG), INTENT(IN) :: NUMBER_GLOBAL_Z_ELEMENTS !<number of elements on z axis
    INTEGER(INTG), INTENT(IN) :: INTERPOLATION_SPECIFICATIONS !<the interpolation specifications
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: NUMBER_OF_DOMAINS
    INTEGER(INTG) :: NUMBER_COMPUTATIONAL_NODES
    INTEGER(INTG) :: MY_COMPUTATIONAL_NODE_NUMBER
    INTEGER(INTG) :: MPI_IERROR
    INTEGER(INTG) :: ANALYTIC_FUNCTION
    INTEGER(INTG) :: EQUATIONS_SET_INDEX

    TYPE(BASIS_TYPE), POINTER :: BASIS
    TYPE(COORDINATE_SYSTEM_TYPE), POINTER :: COORDINATE_SYSTEM
    TYPE(GENERATED_MESH_TYPE), POINTER :: GENERATED_MESH
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: ANALYTIC_FIELD,GEOMETRIC_FIELD
    TYPE(PROBLEM_TYPE), POINTER :: PROBLEM
    TYPE(REGION_TYPE), POINTER :: REGION,WORLD_REGION
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    
    CALL ENTERS("ANALYTICLAPLACE_GENERIC",ERR,ERROR,*999)    

    !Intialise cmiss
    NULLIFY(WORLD_REGION)
    CALL CMISS_INITIALISE(WORLD_REGION,ERR,ERROR,*999)
  
    !Get the number of computational nodes
    NUMBER_COMPUTATIONAL_NODES=COMPUTATIONAL_NODES_NUMBER_GET(ERR,ERROR)
    IF(ERR/=0) GOTO 999
    !Get my computational node number
    MY_COMPUTATIONAL_NODE_NUMBER=COMPUTATIONAL_NODE_NUMBER_GET(ERR,ERROR)
    IF(ERR/=0) GOTO 999
    NUMBER_OF_DOMAINS=NUMBER_COMPUTATIONAL_NODES
    
    !Broadcast the number of elements in the X & Y directions and the number of partitions to the other computational nodes
    CALL MPI_BCAST(NUMBER_GLOBAL_X_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
    CALL MPI_BCAST(NUMBER_GLOBAL_Y_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
    CALL MPI_BCAST(NUMBER_GLOBAL_Z_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
    CALL MPI_BCAST(NUMBER_OF_DOMAINS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
    CALL MPI_BCAST(INTERPOLATION_SPECIFICATIONS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)

    !Start the creation of a new RC coordinate system
    NULLIFY(COORDINATE_SYSTEM)
    CALL COORDINATE_SYSTEM_CREATE_START(1,COORDINATE_SYSTEM,ERR,ERROR,*999)
    IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
      !Set the coordinate system to be 2D
      CALL COORDINATE_SYSTEM_DIMENSION_SET(COORDINATE_SYSTEM,2,ERR,ERROR,*999)
    ELSE
      !Set the coordinate system to be 3D
      CALL COORDINATE_SYSTEM_DIMENSION_SET(COORDINATE_SYSTEM,3,ERR,ERROR,*999)
    ENDIF
    !Finish the creation of the coordinate system
    CALL COORDINATE_SYSTEM_CREATE_FINISH(COORDINATE_SYSTEM,ERR,ERROR,*999)

    !Start the creation of the region
    NULLIFY(REGION)
    CALL REGION_CREATE_START(1,WORLD_REGION,REGION,ERR,ERROR,*999)
    !Set the regions coordinate system to the 2D RC coordinate system that we have created
    CALL REGION_COORDINATE_SYSTEM_SET(REGION,COORDINATE_SYSTEM,ERR,ERROR,*999)
    !Finish the creation of the region
    CALL REGION_CREATE_FINISH(REGION,ERR,ERROR,*999)

  
    !Start the creation of a basis (default is trilinear lagrange)
    NULLIFY(BASIS)
    CALL BASIS_CREATE_START(1,BASIS,ERR,ERROR,*999)
    IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
      !Set the basis to be a bilinear basis
      CALL BASIS_NUMBER_OF_XI_SET(BASIS,2,ERR,ERROR,*999)
      CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/INTERPOLATION_SPECIFICATIONS,INTERPOLATION_SPECIFICATIONS/),ERR,ERROR,*999)
    ELSE
      !Set the basis to be a trilinear basis
      CALL BASIS_NUMBER_OF_XI_SET(BASIS,3,ERR,ERROR,*999)
      CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/INTERPOLATION_SPECIFICATIONS,INTERPOLATION_SPECIFICATIONS, &
          & INTERPOLATION_SPECIFICATIONS/),ERR,ERROR,*999)
    ENDIF
    !Finish the creation of the basis
    CALL BASIS_CREATE_FINISH(BASIS,ERR,ERROR,*999)

    !Start the creation of a generated mesh in the region
    NULLIFY(GENERATED_MESH)
    NULLIFY(MESH)
    CALL GENERATED_MESH_CREATE_START(1,REGION,GENERATED_MESH,ERR,ERROR,*999)
    !Set up a regular 100x100 mesh
    CALL GENERATED_MESH_TYPE_SET(GENERATED_MESH,1, &
        & ERR,ERROR,*999)
    CALL GENERATED_MESH_BASIS_SET(GENERATED_MESH,BASIS,ERR,ERROR,*999)
    !Define the mesh on the region
    IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
      CALL GENERATED_MESH_EXTENT_SET(GENERATED_MESH,(/WIDTH,HEIGHT/),ERR,ERROR,*999)
      CALL GENERATED_MESH_NUMBER_OF_ELEMENTS_SET(GENERATED_MESH,(/NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS/), &
        & ERR,ERROR,*999)
      CALL GENERATED_MESH_ORIGIN_SET(GENERATED_MESH,ORIGIN,ERR,ERROR,*999)
    ELSE
      CALL GENERATED_MESH_EXTENT_SET(GENERATED_MESH,(/WIDTH,HEIGHT,LENGTH/),ERR,ERROR,*999)
      CALL GENERATED_MESH_NUMBER_OF_ELEMENTS_SET(GENERATED_MESH,(/NUMBER_GLOBAL_X_ELEMENTS, &
        & NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS/), ERR,ERROR,*999)
    ENDIF
    !Finish the creation of a generated mesh in the region
    CALL GENERATED_MESH_CREATE_FINISH(GENERATED_MESH,1,MESH,ERR,ERROR,*999)
    
    !Create a decomposition
    NULLIFY(DECOMPOSITION)
    CALL DECOMPOSITION_CREATE_START(1,MESH,DECOMPOSITION,ERR,ERROR,*999)
    !Set the decomposition to be a general decomposition with the specified number of domains
    CALL DECOMPOSITION_TYPE_SET(DECOMPOSITION,DECOMPOSITION_CALCULATED_TYPE,ERR,ERROR,*999)
    CALL DECOMPOSITION_NUMBER_OF_DOMAINS_SET(DECOMPOSITION,NUMBER_OF_DOMAINS,ERR,ERROR,*999)
    CALL DECOMPOSITION_CREATE_FINISH(MESH,DECOMPOSITION,ERR,ERROR,*999)

    !Start to create a default (geometric) field on the region
    NULLIFY(GEOMETRIC_FIELD)
    CALL FIELD_CREATE_START(1,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
    !Set the decomposition to use
    CALL FIELD_MESH_DECOMPOSITION_SET(GEOMETRIC_FIELD,DECOMPOSITION,ERR,ERROR,*999)
    !Set the domain to be used by the field components
    !NB these are needed now as the default mesh component number is 1
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,1,1,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,2,1,ERR,ERROR,*999)
    IF(NUMBER_GLOBAL_Z_ELEMENTS/=0) THEN
      CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,3,1,ERR,ERROR,*999)
    ENDIF
    !Finish creating the field
    CALL FIELD_CREATE_FINISH(GEOMETRIC_FIELD,ERR,ERROR,*999)

    !Update the geometric field parameters
    CALL GENERATED_MESH_GEOMETRIC_PARAMETERS_CALCULATE(GEOMETRIC_FIELD,GENERATED_MESH,ERR,ERROR,*999)

    !Create the equations_set
    NULLIFY(EQUATIONS_SET)
    CALL EQUATIONS_SET_CREATE_START(1,REGION,GEOMETRIC_FIELD,EQUATIONS_SET,ERR,ERROR,*999)
    !Set the equations set to be a standard Laplace problem
    CALL EQUATIONS_SET_SPECIFICATION_SET(EQUATIONS_SET,EQUATIONS_SET_CLASSICAL_FIELD_CLASS,EQUATIONS_SET_LAPLACE_EQUATION_TYPE, &
      & EQUATIONS_SET_STANDARD_LAPLACE_SUBTYPE,ERR,ERROR,*999)
    !Finish creating the equations set
    CALL EQUATIONS_SET_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)
  
    !Create the equations set analytic field variables
    NULLIFY(DEPENDENT_FIELD)
    CALL EQUATIONS_SET_DEPENDENT_CREATE_START(EQUATIONS_SET,2,DEPENDENT_FIELD,ERR,ERROR,*999)
    !Finish the equations set dependent field variables
    CALL EQUATIONS_SET_DEPENDENT_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

    !Create the equations set analytic field variables
    NULLIFY(ANALYTIC_FIELD)
    IF(NUMBER_GLOBAL_Z_ELEMENTS/=0) THEN
      ANALYTIC_FUNCTION=EQUATIONS_SET_LAPLACE_EQUATION_THREE_DIM_2
    ELSE
      ANALYTIC_FUNCTION=EQUATIONS_SET_LAPLACE_EQUATION_TWO_DIM_2
    ENDIF
    CALL EQUATIONS_SET_ANALYTIC_CREATE_START(EQUATIONS_SET,ANALYTIC_FUNCTION,3,ANALYTIC_FIELD,ERR,ERROR,*999)
    !Finish the equations set analtyic field variables
    CALL EQUATIONS_SET_ANALYTIC_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

    !Create the equations set equations
    NULLIFY(EQUATIONS)
    CALL EQUATIONS_SET_EQUATIONS_CREATE_START(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*999)
    !Set the equations matrices sparsity type
    CALL EQUATIONS_SPARSITY_TYPE_SET(EQUATIONS,EQUATIONS_SPARSE_MATRICES,ERR,ERROR,*999)
    CALL EQUATIONS_SET_EQUATIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

    !Set up the boundary conditions as per the analytic solution
    CALL EQUATIONS_SET_BOUNDARY_CONDITIONS_ANALYTIC(EQUATIONS_SET,ERR,ERROR,*999)
  
    !Create the problem
    NULLIFY(PROBLEM)
    CALL PROBLEM_CREATE_START(1,PROBLEM,ERR,ERROR,*999)
    !Set the problem to be a standard Laplace problem
    CALL PROBLEM_SPECIFICATION_SET(PROBLEM,PROBLEM_CLASSICAL_FIELD_CLASS,PROBLEM_LAPLACE_EQUATION_TYPE, &
      & PROBLEM_STANDARD_LAPLACE_SUBTYPE,ERR,ERROR,*999)
    !Finish creating the problem
    CALL PROBLEM_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

    !Create the problem control loop
    CALL PROBLEM_CONTROL_LOOP_CREATE_START(PROBLEM,ERR,ERROR,*999)
    !Finish creating the problem control
    CALL PROBLEM_CONTROL_LOOP_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

    !Start the creation of the problem solver
    NULLIFY(SOLVER)
    CALL PROBLEM_SOLVERS_CREATE_START(PROBLEM,ERR,ERROR,*999)
    !Finish the creation of the problem solver
    CALL PROBLEM_SOLVERS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

    !Create the problem solver equations
    NULLIFY(SOLVER_EQUATIONS)
    CALL PROBLEM_SOLVER_EQUATIONS_CREATE_START(PROBLEM,ERR,ERROR,*999)
    CALL PROBLEM_SOLVER_GET(PROBLEM,CONTROL_LOOP_NODE,1,SOLVER,ERR,ERROR,*999)
    CALL SOLVER_SOLVER_EQUATIONS_GET(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*999)
    CALL SOLVER_EQUATIONS_SPARSITY_TYPE_SET(SOLVER_EQUATIONS,SOLVER_SPARSE_MATRICES,ERR,ERROR,*999)
    !Add in the equations set
    CALL SOLVER_EQUATIONS_EQUATIONS_SET_ADD(SOLVER_EQUATIONS,EQUATIONS_SET,EQUATIONS_SET_INDEX,ERR,ERROR,*999)
    !Finish the problem solver equations
    CALL PROBLEM_SOLVER_EQUATIONS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

    !Solve the problem
    CALL PROBLEM_SOLVE(PROBLEM,ERR,ERROR,*999)
    
    CALL EXITS("ANALYTICLAPLACE_GENERIC")
    RETURN
999 CALL ERRORS("ANALYTICLAPLACE_GENERIC",ERR,ERROR)
    CALL EXITS("ANALYTICLAPLACE_GENERIC")
    RETURN 1
  
  END SUBROUTINE ANALYTICLAPLACE_GENERIC

END PROGRAM ANALYTICLAPLACEEXAMPLE 