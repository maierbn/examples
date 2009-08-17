MODULE EXPORT_CMGUI

  USE BASE_ROUTINES
  USE LISTS
  USE BASIS_ROUTINES
  USE MESH_ROUTINES
  USE NODE_ROUTINES
  USE COMP_ENVIRONMENT
  USE COORDINATE_ROUTINES
  USE ISO_VARYING_STRING
  USE REGION_ROUTINES
  USE MACHINE_CONSTANTS
  USE KINDS
  USE FIELD_ROUTINES
  USE ISO_VARYING_STRING
  USE ISO_C_BINDING
  USE STRINGS
  USE TYPES
  USE CONSTANTS
  USE MPI
  USE CMISS_MPI
  USE INPUT_OUTPUT

  USE DARCY_PARAMETERS
  USE DARCY_PARAMS_CONVSTUDY

  IMPLICIT NONE

  !1=M, 2=V, 3=P !


  INTEGER, DIMENSION(:), ALLOCATABLE:: NodesPerElement
  DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE::ElementNodesScales
  INTEGER, DIMENSION(:,:), ALLOCATABLE::ElementNodes
  INTEGER:: NumberOfFields
  INTEGER:: NumberOfDimensions
  INTEGER:: ValueIndex
  INTEGER:: NumberOfVariableComponents
  INTEGER:: NumberOfMeshComponents
  INTEGER:: NumberOfMaterialComponents
  INTEGER:: NumberOfNodesDefined
  INTEGER:: NumberOfFieldComponent(3)
  INTEGER:: NumberOfElements
  INTEGER:: GlobalElementNumber(10)
  INTEGER:: MaxNodesPerElement
  INTEGER:: MaxNodesPerMeshComponent

  INTEGER:: ELEMENT_NUMBER
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: XI_COORDINATES,COORDINATES
   DOUBLE PRECISION:: test

  INTEGER:: lagrange_simplex

  INTEGER, DIMENSION(:), ALLOCATABLE:: NodesPerMeshComponent

  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeXValue
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeYValue
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeZValue 
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeUValue 
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeVValue 
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeWValue 
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodePValue 
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeMUValue 

  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeUValue_analytic
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeVValue_analytic 
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeWValue_analytic 
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodePValue_analytic 

  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeUValue_error
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeVValue_error
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodeWValue_error
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE:: NodePValue_error

  INTEGER, DIMENSION(:), ALLOCATABLE::SimplexOutputHelp


  TYPE(FIELD_TYPE), POINTER :: FIELD
  TYPE(FIELD_INTERPOLATION_PARAMETERS_TYPE), POINTER :: INTERPOLATION_PARAMETERS
  TYPE(FIELD_INTERPOLATED_POINT_TYPE), POINTER :: INTERPOLATED_POINT

  DOUBLE PRECISION:: ScaleFactorsPerElementNodes(10,10)

  DOUBLE PRECISION:: MaxNodeUValue_error, MaxNodeVValue_error, MaxNodeWValue_error, MaxNodePValue_error

  INTEGER:: TRI_BASIS, TET_BASIS, QUAD_BASIS, HEX_BASIS
  CHARACTER*2 NMs(99),KNOT




  CONTAINS


  !HERE THE TYPES DEFINED ABOVE ARE FILLED WITH THE DATA PROVIDED  
  SUBROUTINE READ_CMGUI_EXE(REGION)

  INTEGER:: I,J,K,L,M,N

  INTEGER :: ERR !<The error code
  TYPE(VARYING_STRING):: ERROR !<The error string

   TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region to get the coordinate system for

       KNOT = '0'
       NMs(1) = '1'
       NMs(2) = '2'
       NMs(3) = '3'
       NMs(4) = '4'
       NMs(5) = '5'
       NMs(6) = '6'
       NMs(7) = '7'
       NMs(8) = '8'
       NMs(9) = '9'
       K = 9
       DO I = 1,9
          K = K + 1
          NMs(K) = TRIM(NMs(I))//TRIM(KNOT)
          DO J = 1,9
             K = K + 1
             NMs(K) = TRIM(NMs(I))//TRIM(NMs(J))
          END DO
       END DO


   NumberOfFields=REGION%fields%number_of_fields
   NumberOfDimensions=REGION%coordinate_system%number_of_dimensions

  NumberOfVariableComponents=REGION%equations_sets%equations_sets(1)%ptr%dependent%dependent_field%&
  &variables(1)%number_of_components

   NumberOfMaterialComponents=REGION%equations_sets%equations_sets(1)%ptr%materials%materials_field%&
   &variables(1)%number_of_components

   NumberOfElements=REGION%meshes%meshes(1)%ptr%number_of_elements
   NumberOfMeshComponents=REGION%meshes%meshes(1)%ptr%number_of_components
   ALLOCATE(NodesPerElement(NumberOfMeshComponents))
   ALLOCATE(NodesPerMeshComponent(NumberOfMeshComponents))
   MaxNodesPerElement=0
   DO I=1,NumberOfMeshComponents
      NodesPerElement(I)=REGION%fields%fields(1)%ptr%geometric_field%decomposition%domain(1)&
      &%ptr%topology%elements%elements(1)%basis%number_of_element_parameters
      NodesPerMeshComponent(I)=REGION%meshes%meshes(1)%ptr%topology(I)%ptr%nodes%number_of_nodes
   END DO


   MaxNodesPerElement=NodesPerElement(1)

   MaxNodesPerMeshComponent=NodesPerMeshComponent(1)

   ALLOCATE(XI_COORDINATES(NumberOfDimensions))
   ALLOCATE(COORDINATES(NumberOfDimensions))

   ALLOCATE(NodeXValue(NodesPerMeshComponent(1)))
   ALLOCATE(NodeYValue(NodesPerMeshComponent(1)))
   ALLOCATE(NodeZValue(NodesPerMeshComponent(1)))
   ALLOCATE(NodeUValue(NodesPerMeshComponent(1)))
   ALLOCATE(NodeVValue(NodesPerMeshComponent(1)))
   ALLOCATE(NodeWValue(NodesPerMeshComponent(1)))
   ALLOCATE(NodePValue(NodesPerMeshComponent(1)))
   ALLOCATE(NodeMUValue(NodesPerMeshComponent(1)))
   ALLOCATE(ElementNodesScales(NumberOfElements,NodesPerElement(1)))
   ALLOCATE(ElementNodes(NumberOfElements,NodesPerElement(1)))

   ALLOCATE(NodeUValue_analytic(NodesPerMeshComponent(1)))
   ALLOCATE(NodeVValue_analytic(NodesPerMeshComponent(1)))
   ALLOCATE(NodeWValue_analytic(NodesPerMeshComponent(1)))
   ALLOCATE(NodePValue_analytic(NodesPerMeshComponent(1)))

   ALLOCATE(NodeUValue_error(NodesPerMeshComponent(1)))
   ALLOCATE(NodeVValue_error(NodesPerMeshComponent(1)))
   ALLOCATE(NodeWValue_error(NodesPerMeshComponent(1)))
   ALLOCATE(NodePValue_error(NodesPerMeshComponent(1)))

! THIS NEEDS TO BE ADJUSTED NOW!!!!!!

    CALL ENTERS("CMGUI OUTPUT",ERR,ERROR,*999)

   FIELD=>REGION%equations_sets%equations_sets(1)%ptr%dependent%dependent_field
   CALL FIELD_INTERPOLATION_PARAMETERS_INITIALISE(FIELD,FIELD_U_VARIABLE_TYPE,INTERPOLATION_PARAMETERS&
   &,ERR,ERROR,*999)
   CALL FIELD_INTERPOLATED_POINT_INITIALISE(INTERPOLATION_PARAMETERS,INTERPOLATED_POINT,ERR,ERROR,*999)

  DO I=1,NumberOfElements
   DO J=1,NodesPerElement(1)
 
      ELEMENT_NUMBER=I
      XI_COORDINATES(1)=(REGION%equations_sets%equations_sets(1)%ptr%equations%interpolation%&
      &geometric_interp_parameters%bases(1)%ptr%node_position_index(J,1)-1.0)/(REGION%equations_sets%&
      &equations_sets(1)%ptr%equations%interpolation%geometric_interp_parameters%bases(1)&
      &%ptr%number_of_nodes_xi(1)-1.0)

      XI_COORDINATES(2)=(REGION%equations_sets%equations_sets(1)%ptr%equations%interpolation%&
      &geometric_interp_parameters%bases(1)%ptr%node_position_index(J,2)-1.0)/(REGION%equations_sets%&
      &equations_sets(1)%ptr%equations%interpolation%geometric_interp_parameters%bases(1)&
      &%ptr%number_of_nodes_xi(2)-1.0)

      IF(NumberOfDimensions==3)THEN
      XI_COORDINATES(3)=(REGION%equations_sets%equations_sets(1)%ptr%equations%interpolation%&
      &geometric_interp_parameters%bases(1)%ptr%node_position_index(J,3)-1.0)/(REGION%equations_sets%&
      &equations_sets(1)%ptr%equations%interpolation%geometric_interp_parameters%bases(1)&
      &%ptr%number_of_nodes_xi(3)-1.0)
      END IF

      !K is global node number
      K=REGION%meshes%meshes(1)%ptr%topology(1)%ptr%elements%elements(I)%global_element_nodes(J)

      IF(NumberOfDimensions==3)THEN
      COORDINATES=(/1,1,1/)
      ELSE IF(NumberOfDimensions==2)THEN
      COORDINATES=(/1,1/)
      END IF

      CALL FIELD_INTERPOLATION_PARAMETERS_ELEMENT_GET(FIELD_VALUES_SET_TYPE,ELEMENT_NUMBER,&
      &INTERPOLATION_PARAMETERS,ERR,ERROR,*999)
 
      CALL FIELD_INTERPOLATE_XI(NO_PART_DERIV,XI_COORDINATES,INTERPOLATED_POINT,ERR,ERROR,*999)

      NodeXValue(K)=REGION%equations_sets%equations_sets(1)%ptr%geometry%geometric_field%variables(1)&
      &%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(K)

      NodeYValue(K)=REGION%equations_sets%equations_sets(1)%ptr%geometry%geometric_field%variables(1)&
      &%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(K+NodesPerMeshComponent(1))

      IF(NumberOfDimensions==3)THEN
      NodeZValue(K)=REGION%equations_sets%equations_sets(1)%ptr%geometry%geometric_field%variables(1)&
      &%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(K+2*NodesPerMeshComponent(1))
      END IF

      NodeUValue(K)=REGION%equations_sets%equations_sets(1)%ptr%dependent%dependent_field%variables(1)&
      &%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(K)
      NodeVValue(K)=REGION%equations_sets%equations_sets(1)%ptr%dependent%dependent_field%variables(1)&
      &%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(K+NodesPerMeshComponent(1))
      IF(NumberOfDimensions==3)THEN
      NodeWValue(K)=REGION%equations_sets%equations_sets(1)%ptr%dependent%dependent_field%variables(1)&
      &%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(K+2*NodesPerMeshComponent(1))
      END IF

! ! !       NodeUValue(K)=INTERPOLATED_POINT%VALUES(1,1)
! ! !       NodeVValue(K)=INTERPOLATED_POINT%VALUES(2,1)
! ! !       NodeWValue(K)=INTERPOLATED_POINT%VALUES(3,1)

      IF(NumberOfDimensions==3)THEN
      NodePValue(K)=INTERPOLATED_POINT%VALUES(4,1)
      ELSE IF(NumberOfDimensions==2)THEN
      NodePValue(K)=INTERPOLATED_POINT%VALUES(3,1)
      END IF

   END DO 
  END DO


   NodeMUValue=REGION%equations_sets%equations_sets(1)%ptr%materials%materials_field%variables(1)%&
   &parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(1)

   IF( NumberOfDimensions==3 )THEN
     !For 3D, the following call works ...
     lagrange_simplex=REGION%equations_sets%equations_sets(1)%ptr%equations%&
     &interpolation%geometric_interp_parameters%bases(1)%ptr%type
   ELSE
     ! ... but the above call does not work for 2D.
     !Thus, for 2D, we hard-wire it to 'quad':
     lagrange_simplex=1
   END IF
                   

  NumberOfFieldComponent(1)=NumberOfDimensions
  NumberOfFieldComponent(2)=NumberOfVariableComponents
  NumberOfFieldComponent(3)=NumberOfMaterialComponents


    DO I=1,NumberOfElements
    DO J=1,NodesPerElement(1)
      ElementNodes(I,J)=REGION%meshes%meshes(1)%ptr%topology(1)%&
      &ptr%elements%elements(I)%global_element_nodes(J)
      ElementNodesScales(I,J)=1.0000000000000000E+00
    END DO
    END DO
    CALL EXITS("CMGUI OUTPUT")
    RETURN
999 CALL ERRORS("CMGUI OUTPUT",ERR,ERROR)


  END SUBROUTINE READ_CMGUI_EXE


! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------

  !HERE THE TYPES DEFINED ABOVE ARE FILLED WITH THE DATA PROVIDED
  SUBROUTINE SEND_CMGUI_EXE
     CALL WRITE_NODE_FILE
     CALL WRITE_ELEMENT_FILE
  END SUBROUTINE SEND_CMGUI_EXE

! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------

  SUBROUTINE WRITE_NODE_FILE

  IMPLICIT NONE

  INTEGER:: I,J,K,L,M,N

  DOUBLE PRECISION:: COORD_X, COORD_Y, COORD_Z, ARG_X, ARG_Y, ARG_Z
  DOUBLE PRECISION:: FACT

  TYPE(VARYING_STRING) :: LOCAL_ERROR    


  IF( TESTCASE == 1 ) THEN
    FACT = PERM_OVER_VIS
  ELSE
    FACT = 2.0_DP * PI * PERM_OVER_VIS / LENGTH
!     FACT = 1.0_DP
  END IF


  IF( ANALYTIC ) THEN
    IF( NumberOfDimensions==2 ) THEN
      DO I = 1,NodesPerMeshComponent(1)
        COORD_X = NodeXValue(I)
        COORD_Y = NodeYValue(I)
        ARG_X = 2.0_DP * PI * COORD_X / LENGTH
        ARG_Y = 2.0_DP * PI * COORD_Y / LENGTH

        IF( TESTCASE == 1 ) THEN
          NodeUValue_analytic(I) = - FACT * ( 2.0_DP * COORD_X + 2.0_DP * COORD_Y )
          NodeVValue_analytic(I) = - FACT * ( 2.0_DP * COORD_X - 2.0_DP * COORD_Y )
          NodePValue_analytic(I) = COORD_X * COORD_X + 2.0_DP * COORD_X * COORD_Y - COORD_Y * COORD_Y
        ELSE
          NodeUValue_analytic(I) = - FACT * COS( ARG_X ) * SIN( ARG_Y ) 
          NodeVValue_analytic(I) = - FACT * SIN( ARG_X ) * COS( ARG_Y ) 
          NodePValue_analytic(I) =          SIN( ARG_X ) * SIN( ARG_Y )
        END IF

        NodeUValue_error(I) = NodeUValue(I) - NodeUValue_analytic(I)
        NodeVValue_error(I) = NodeVValue(I) - NodeVValue_analytic(I)
        NodePValue_error(I) = NodePValue(I) - NodePValue_analytic(I)
      END DO
    ELSE IF( NumberOfDimensions==3 ) THEN
      DO I = 1,NodesPerMeshComponent(1)

        COORD_X = NodeXValue(I)
        COORD_Y = NodeYValue(I)
        COORD_Z = NodeZValue(I)

        ARG_X = 2.0_DP * PI * COORD_X / LENGTH
        ARG_Y = 2.0_DP * PI * COORD_Y / LENGTH
        ARG_Z = 2.0_DP * PI * COORD_Z / LENGTH

        IF( TESTCASE == 1 ) THEN
          NodeUValue_analytic(I) = - FACT * ( 2.0_DP * COORD_X + 2.0_DP * COORD_Y + COORD_Z )
          NodeVValue_analytic(I) = - FACT * ( 2.0_DP * COORD_X - 2.0_DP * COORD_Y + COORD_Z )
          NodeWValue_analytic(I) = - FACT * ( 3.0_DP + COORD_X + COORD_Y )
          NodePValue_analytic(I) = COORD_X * COORD_X + 2.0_DP * COORD_X * COORD_Y - COORD_Y * COORD_Y + &
            & 3.0_DP * COORD_Z + COORD_Z * COORD_X  + COORD_Z * COORD_Y 
        ELSE
          NodeUValue_analytic(I) = - FACT * COS( ARG_X ) * SIN( ARG_Y )  * SIN( ARG_Z ) 
          NodeVValue_analytic(I) = - FACT * SIN( ARG_X ) * COS( ARG_Y )  * SIN( ARG_Z )  
          NodeWValue_analytic(I) = - FACT * SIN( ARG_X ) * SIN( ARG_Y )  * COS( ARG_Z )  
          NodePValue_analytic(I) =          SIN( ARG_X ) * SIN( ARG_Y )  * SIN( ARG_Z )  
        END IF

        NodeUValue_error(I) = NodeUValue(I) - NodeUValue_analytic(I)
        NodeVValue_error(I) = NodeVValue(I) - NodeVValue_analytic(I)
        NodeWValue_error(I) = NodeWValue(I) - NodeWValue_analytic(I)
        NodePValue_error(I) = NodePValue(I) - NodePValue_analytic(I)

      END DO

    END IF

  END IF


       OPEN(UNIT=14, FILE='./output/cmgui.exnode',STATUS='unknown')

! WRITING HEADER INFORMATION

       WRITE(14,*) 'Group name: OpenCMISS'
       IF( ANALYTIC ) THEN
       WRITE(14,*) '#Fields=',TRIM(NMs(NumberOfFields + 2))
!        WRITE(14,*) '#Fields=',TRIM(NMs(NumberOfFields + 1))
       ELSE
       WRITE(14,*) '#Fields=',TRIM(NMs(NumberOfFields))
       END IF
       ValueIndex=1
       WRITE(14,*) ' 1) coordinates,  coordinate, rectangular cartesian, #Components=',TRIM(NMs(NumberOfDimensions))
       DO I=1,NumberOfDimensions
         IF(I==1) THEN
           WRITE(14,*) '   x.  Value index= ',TRIM(NMs(ValueIndex)),',     #Derivatives= 0'
         ELSE IF(I==2) THEN
           WRITE(14,*) '   y.  Value index= ',TRIM(NMs(ValueIndex)),',     #Derivatives= 0'
         ELSE
           WRITE(14,*) '   z.  Value index= ',TRIM(NMs(ValueIndex)),',     #Derivatives= 0'
         END IF
         ValueIndex=ValueIndex+1
       END DO
       WRITE(14,*) ' 2) general,  field,  rectangular cartesian, #Components=',TRIM(NMs(NumberOfVariableComponents))
       DO I=1,NumberOfVariableComponents
         WRITE(14,*)  '   ',TRIM(NMs(I)),'.  Value index= ',TRIM(NMs(ValueIndex)),',     #Derivatives= 0' 
         ValueIndex=ValueIndex+1
       END DO
       WRITE(14,*) ' 3) material,  field,  rectangular cartesian, #Components=',TRIM(NMs(NumberOfMaterialComponents))
       DO I=1,NumberOfMaterialComponents
         WRITE(14,*)  '   ',TRIM(NMs(I)),'.  Value index= ',TRIM(NMs(ValueIndex)),',     #Derivatives= 0' 
         ValueIndex=ValueIndex+1
       END DO

       IF( ANALYTIC ) THEN
         WRITE(14,*) ' 4) exact,  field,  rectangular cartesian, #Components=',TRIM(NMs(NumberOfVariableComponents))
         DO I=1,NumberOfVariableComponents
           WRITE(14,*)  '   ',TRIM(NMs(I)),'.  Value index= ',TRIM(NMs(ValueIndex)),',     #Derivatives= 0' 
           ValueIndex=ValueIndex+1
         END DO

         WRITE(14,*) ' 5) error,  field,  rectangular cartesian, #Components=',TRIM(NMs(NumberOfVariableComponents))
!          WRITE(14,*) ' 4) error,  field,  rectangular cartesian, #Components=',TRIM(NMs(NumberOfVariableComponents))
         DO I=1,NumberOfVariableComponents
           WRITE(14,*)  '   ',TRIM(NMs(I)),'.  Value index= ',TRIM(NMs(ValueIndex)),',     #Derivatives= 0' 
           ValueIndex=ValueIndex+1
         END DO
       END IF


! NOW WRITE NODE INFORMATION
! ! ! 
            DO I = 1,NodesPerMeshComponent(1)
               WRITE(14,*) ' Node: ',I

                  WRITE(14,'("    ", es25.16 )')NodeXValue(I)
                  WRITE(14,'("    ", es25.16 )')NodeYValue(I)
                  IF(NumberOfDimensions==3) THEN
                    WRITE(14,'("    ", es25.16 )')NodeZValue(I)
                  END IF
                  WRITE(14,'("    ", es25.16 )')NodeUValue(I)
                  WRITE(14,'("    ", es25.16 )')NodeVValue(I)
                  IF(NumberOfDimensions==3) THEN
                    WRITE(14,'("    ", es25.16 )')NodeWValue(I)
                  END IF
                  WRITE(14,'("    ", es25.16 )')NodePValue(I)
                  WRITE(14,'("    ", es25.16 )')NodeMUValue(I)

                  IF( ANALYTIC ) THEN
                    WRITE(14,'("    ", es25.16 )')NodeUValue_analytic(I)
                    WRITE(14,'("    ", es25.16 )')NodeVValue_analytic(I)
                    IF(NumberOfDimensions==3) THEN
                      WRITE(14,'("    ", es25.16 )')NodeWValue_analytic(I)
                    END IF
                    WRITE(14,'("    ", es25.16 )')NodePValue_analytic(I)

                    WRITE(14,'("    ", es25.16 )')NodeUValue_error(I)
                    WRITE(14,'("    ", es25.16 )')NodeVValue_error(I)
                    IF(NumberOfDimensions==3) THEN
                      WRITE(14,'("    ", es25.16 )')NodeWValue_error(I)
                    END IF
                    WRITE(14,'("    ", es25.16 )')NodePValue_error(I)
                  END IF

            END DO


       WRITE(14,*) ' '
       CLOSE(14)

  WRITE(*,*)'Writing Nodes...'


  ! ----------------------------------------------------------
  ! Write file to monitor convergence of discretization error
  IF( ANALYTIC ) THEN
    OPEN(UNIT=23, FILE='./output/conv.node',STATUS='unknown')

    MaxNodeUValue_error = 0.0
    MaxNodeVValue_error = 0.0
    MaxNodeWValue_error = 0.0
    MaxNodePValue_error = 0.0

    IF( NumberOfDimensions==2 ) THEN
      DO I = 1,NodesPerMeshComponent(1)
        IF( abs(mod( ((NodeXValue(I)-X1) / max_node_spacing), 1.0)) < GEOM_TOL ) THEN
          IF( abs(mod( ((NodeYValue(I)-Y1) / max_node_spacing), 1.0)) < GEOM_TOL ) THEN

              WRITE(23,'("    ", es25.16 )')NodeXValue(I)
              WRITE(23,'("    ", es25.16 )')NodeYValue(I)

              WRITE(23,'("    ", es25.16 )')NodeUValue_error(I)
              WRITE(23,'("    ", es25.16 )')NodeVValue_error(I)
              WRITE(23,'("    ", es25.16 )')NodePValue_error(I)

              WRITE(23,*) ' '

              IF( abs(NodeUValue_error(I)) > MaxNodeUValue_error ) MaxNodeUValue_error = abs(NodeUValue_error(I))
              IF( abs(NodeVValue_error(I)) > MaxNodeVValue_error ) MaxNodeVValue_error = abs(NodeVValue_error(I))
              IF( abs(NodePValue_error(I)) > MaxNodePValue_error ) MaxNodePValue_error = abs(NodePValue_error(I))

          END IF
        END IF
      END DO
      WRITE(23,'("    MaxNodeUValue_error = ", es25.16 )')MaxNodeUValue_error
      WRITE(23,'("    MaxNodeVValue_error = ", es25.16 )')MaxNodeVValue_error
      WRITE(23,'("    MaxNodePValue_error = ", es25.16 )')MaxNodePValue_error
      WRITE(23,*) ' '
    ELSE IF( NumberOfDimensions==3 ) THEN
      DO I = 1,NodesPerMeshComponent(1)
        IF( abs(mod( ((NodeXValue(I)-X1) / max_node_spacing), 1.0)) < GEOM_TOL ) THEN
          IF( abs(mod( ((NodeYValue(I)-Y1) / max_node_spacing), 1.0)) < GEOM_TOL ) THEN
            IF( abs(mod( ((NodeZValue(I)-Z1) / max_node_spacing), 1.0)) < GEOM_TOL ) THEN

              WRITE(23,'("    ", es25.16 )')NodeXValue(I)
              WRITE(23,'("    ", es25.16 )')NodeYValue(I)
              WRITE(23,'("    ", es25.16 )')NodeZValue(I)

              WRITE(23,'("    ", es25.16 )')NodeUValue_error(I)
              WRITE(23,'("    ", es25.16 )')NodeVValue_error(I)
              WRITE(23,'("    ", es25.16 )')NodeWValue_error(I)
              WRITE(23,'("    ", es25.16 )')NodePValue_error(I)

              WRITE(23,*) ' '

              IF( abs(NodeUValue_error(I)) > MaxNodeUValue_error ) MaxNodeUValue_error = abs(NodeUValue_error(I))
              IF( abs(NodeVValue_error(I)) > MaxNodeVValue_error ) MaxNodeVValue_error = abs(NodeVValue_error(I))
              IF( abs(NodeWValue_error(I)) > MaxNodeWValue_error ) MaxNodeWValue_error = abs(NodeWValue_error(I))
              IF( abs(NodePValue_error(I)) > MaxNodePValue_error ) MaxNodePValue_error = abs(NodePValue_error(I))

            END IF
          END IF
        END IF
      END DO
      WRITE(23,'("    MaxNodeUValue_error = ", es25.16 )')MaxNodeUValue_error
      WRITE(23,'("    MaxNodeVValue_error = ", es25.16 )')MaxNodeVValue_error
      IF( NumberOfDimensions==3 ) THEN
        WRITE(23,'("    MaxNodeWValue_error = ", es25.16 )')MaxNodeWValue_error
      END IF
      WRITE(23,'("    MaxNodePValue_error = ", es25.16 )')MaxNodePValue_error
      WRITE(23,*) ' '
    END IF

    CLOSE(23)
  END IF
  ! ----------------------------------------------------------


  END SUBROUTINE WRITE_NODE_FILE


! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------

  SUBROUTINE WRITE_ELEMENT_FILE

   IMPLICIT NONE

        INTEGER:: I,J,K,L,M,N

        CHARACTER*60 ELEM_TYPE


       OPEN(UNIT=5,FILE='./output/cmgui.exelem',STATUS='unknown')
       WRITE(5,*) 'Group name: OpenCMISS'

       IF(lagrange_simplex==2) THEN
         WRITE(5,*) 'Shape.  Dimension=',TRIM(NMs(NumberOfDimensions)),', simplex(2;3)*simplex*simplex'
         IF(MaxNodesPerElement==3) THEN
           WRITE(5,*) '#Scale factor sets= 1'
           WRITE(5,*) ' l.simplex(2)*l.simplex, #Scale factors= ', NodesPerElement(1)
         ELSE IF(MaxNodesPerElement==4) THEN
           WRITE(5,*) '#Scale factor sets= 1'
           WRITE(5,*) ' l.simplex(2;3)*l.simplex*l.simplex, #Scale factors= ', NodesPerElement(1)
          ELSE IF (MaxNodesPerElement== 10 ) THEN
           WRITE(5,*) '#Scale factor sets= 1'
           WRITE(5,*) ' q.simplex(2;3)*q.simplex*q.simplex, #Scale factors= ', NodesPerElement(1)
         ELSE
           WRITE(5,*) '#Scale factor sets= 0'
         END IF

       ELSE IF (lagrange_simplex==1) THEN
         WRITE(5,*) 'Shape.  Dimension= ',TRIM(NMs(NumberOfDimensions))
         WRITE(5,*) '#Scale factor sets= 1'
         IF(NumberOfDimensions==2) THEN
             IF(MaxNodesPerElement==4) THEN
                   WRITE(5,*) 'l.Lagrange*l.Lagrange, #Scale factors=',NodesPerElement(1)
             ELSE IF(MaxNodesPerElement==9) THEN
                   WRITE(5,*) 'q.Lagrange*q.Lagrange, #Scale factors=',NodesPerElement(1)
             ELSE IF(MaxNodesPerElement==16) THEN
                   WRITE(5,*) 'c.Lagrange*c.Lagrange, #Scale factors=',NodesPerElement(1)
             END IF
         ELSE
             IF(MaxNodesPerElement==8) THEN
                   WRITE(5,*) 'l.Lagrange*l.Lagrange*l.Lagrange, #Scale factors=',NodesPerElement(1)
             ELSE IF(MaxNodesPerElement==27) THEN
                   WRITE(5,*) 'q.Lagrange*q.Lagrange*q.Lagrange, #Scale factors=',NodesPerElement(1)
             ELSE IF(MaxNodesPerElement==64) THEN
                   WRITE(5,*) 'c.Lagrange*c.Lagrange*c.Lagrange, #Scale factors=',NodesPerElement(1)
             END IF
         END IF
      END IF

       WRITE(5,*) '#Nodes= ',TRIM(NMs(NodesPerElement(1)))
       WRITE(5,*) '#Fields= ',TRIM(Nms(NumberOfFields))


       DO I=1,NumberOfFields


          IF(I==1)THEN
           WRITE(5,*)' 1) coordinates,  coordinate, rectangular cartesian, #Components= ',TRIM(NMs(NumberOfDimensions))
          ELSE IF(I==2) THEN
           WRITE(5,*)' 2) general,  field,  rectangular cartesian, #Components= ',TRIM(NMs(NumberOfVariableComponents))
          ELSE IF(I==3) THEN
           WRITE(5,*)' 3) material,  field,  rectangular cartesian, #Components= ',TRIM(NMs(NumberOfMaterialComponents))
          END IF

      DO J=1,NumberOfFieldComponent(I)

        IF(NumberOfDimensions==2) THEN

             IF(I==1)THEN
              IF(J==1) THEN
                IF(MaxNodesPerElement==4)THEN
                    WRITE(5,*)'   x.   l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==9) THEN
                    WRITE(5,*)'   x.   q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==16)  THEN
                    WRITE(5,*)'   x.   c.Lagrange*c.Lagrange, no modify, standard node based.'
                END IF 
               ELSE IF(J==2) THEN
                IF(MaxNodesPerElement==4) THEN
                    WRITE(5,*)'   y.   l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==9)  THEN
                    WRITE(5,*)'   y.   q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==16)  THEN
                    WRITE(5,*)'   y.   c.Lagrange*c.Lagrange, no modify, standard node based.'
                END IF
               ELSE IF(J==3) THEN
                IF(MaxNodesPerElement==4) THEN
                    WRITE(5,*)'   z.   l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==9)  THEN
                    WRITE(5,*)'   z.   q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==16)  THEN
                    WRITE(5,*)'   z.   c.Lagrange*c.Lagrange, no modify, standard node based.'
                END IF
              END IF
             ELSE
                IF(MaxNodesPerElement==4) THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.   l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==9)  THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.   q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==16)  THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.   c.Lagrange*c.Lagrange, no modify, standard node based.'
                END IF
             END IF


          ELSE IF(NumberOfDimensions==3) THEN

             IF(I==1)THEN
              IF(J==1) THEN
                IF(MaxNodesPerElement==8) THEN
                    WRITE(5,*)'   x.   l.Lagrange*l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==27)  THEN
                    WRITE(5,*)'   x.   q.Lagrange*q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==64)  THEN
                    WRITE(5,*)'   x.   c.Lagrange*c.Lagrange*c.Lagrange, no modify, standard node based.'

                ELSE IF(MaxNodesPerElement==4)  THEN
                    WRITE(5,*)'   x.  l.simplex(2;3)*l.simplex*l.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==10)  THEN
                    WRITE(5,*)'   x.  q.simplex(2;3)*q.simplex*q.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==20)  THEN
                    WRITE(5,*)'   x.  c.simplex(2;3)*c.simplex*c.simplex, no modify, standard node based.'

                END IF 
               ELSE IF(J==2) THEN
                IF(MaxNodesPerElement==8) THEN
                    WRITE(5,*)'   y.   l.Lagrange*l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==27)  THEN
                    WRITE(5,*)'   y.   q.Lagrange*q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==64)  THEN
                    WRITE(5,*)'   y.   c.Lagrange*c.Lagrange*c.Lagrange, no modify, standard node based.'

                ELSE IF(MaxNodesPerElement==4)  THEN
                    WRITE(5,*)'   y.  l.simplex(2;3)*l.simplex*l.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==10)  THEN
                    WRITE(5,*)'   y.  q.simplex(2;3)*q.simplex*q.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==20)  THEN
                    WRITE(5,*)'   y.  c.simplex(2;3)*c.simplex*c.simplex, no modify, standard node based.'


                END IF
               ELSE IF(J==3) THEN
                IF(MaxNodesPerElement==8) THEN
                    WRITE(5,*)'   z.   l.Lagrange*l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==27)  THEN
                    WRITE(5,*)'   z.   q.Lagrange*q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==64)  THEN
                    WRITE(5,*)'   z.   c.Lagrange*c.Lagrange*c.Lagrange, no modify, standard node based.'

                ELSE IF(MaxNodesPerElement==4)  THEN
                    WRITE(5,*)'   z.  l.simplex(2;3)*l.simplex*l.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==10)  THEN
                    WRITE(5,*)'   z.  q.simplex(2;3)*q.simplex*q.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==20)  THEN
                    WRITE(5,*)'   z.  c.simplex(2;3)*c.simplex*c.simplex, no modify, standard node based.'



                END IF
              END IF
             ELSE
                IF(MaxNodesPerElement==8) THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.   l.Lagrange*l.Lagrange*l.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==27)  THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.   q.Lagrange*q.Lagrange*q.Lagrange, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==64)  THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.   c.Lagrange*c.Lagrange*c.Lagrange, no modify, standard node based.'

                ELSE IF(MaxNodesPerElement==4)  THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.  l.simplex(2;3)*l.simplex*l.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==10)  THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.  q.simplex(2;3)*q.simplex*q.simplex, no modify, standard node based.'
                ELSE IF(MaxNodesPerElement==20)  THEN
                WRITE(5,*)'   ',TRIM(NMs(J)),'.  c.simplex(2;3)*c.simplex*c.simplex, no modify, standard node based.'


                END IF
             END IF
          END IF






               WRITE(5,*) '   #Nodes= ',TRIM(NMs(MaxNodesPerElement))



           DO K = 1,MaxNodesPerElement
               WRITE(5,*) '    ',TRIM(NMs(K)),'.  #Values=1'
               WRITE(5,*) '     Value indices:     1'
               WRITE(5,*) '     Scale factor indices:   ',TRIM(NMs(K))
           END DO

          END DO

        END DO

       IF(lagrange_simplex==2) THEN

       ALLOCATE(SimplexOutputHelp(NodesPerElement(1)))

       DO K = 1,NumberOfElements
         IF(NumberOfDimensions==2)THEN
              SimplexOutputHelp=ElementNodes(K,1:NodesPerElement(1))
         ELSE IF(NumberOfDimensions==3) THEN
              SimplexOutputHelp(1)=ElementNodes(K,1)
              SimplexOutputHelp(2)=ElementNodes(K,5)
              SimplexOutputHelp(3)=ElementNodes(K,2)
              SimplexOutputHelp(4)=ElementNodes(K,7)
              SimplexOutputHelp(5)=ElementNodes(K,10)
              SimplexOutputHelp(6)=ElementNodes(K,4)
              SimplexOutputHelp(7)=ElementNodes(K,6)
              SimplexOutputHelp(8)=ElementNodes(K,8)
              SimplexOutputHelp(9)=ElementNodes(K,9)
              SimplexOutputHelp(10)=ElementNodes(K,3)
         END IF
            WRITE(5,*) 'Element:     ', K,' 0  0'
            WRITE(5,*) '   Nodes:'
            WRITE(5,*) '   ', SimplexOutputHelp
            WRITE(5,*) '   Scale factors:'
            WRITE(5,*) '   ',ElementNodesScales(K,1:NodesPerElement(1))
        END DO

       ELSE IF (lagrange_simplex==1) THEN

       DO K = 1,NumberOfElements
            WRITE(5,*) 'Element:     ', K,' 0  0'
            WRITE(5,*) '   Nodes:'
            WRITE(5,*) '   ', ElementNodes(K,1:NodesPerElement(1))
            WRITE(5,*) '   Scale factors:'
            WRITE(5,*) '   ',ElementNodesScales(K,1:NodesPerElement(1))
       END DO

       END IF

       WRITE(5,*) ' '
       CLOSE(5)



  WRITE(*,*)'Writing Elements...'

  END SUBROUTINE WRITE_ELEMENT_FILE


! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------

END MODULE EXPORT_CMGUI