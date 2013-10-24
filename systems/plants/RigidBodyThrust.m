classdef RigidBodyThrust < RigidBodyForceElement

  properties
    kinframe
    axis
    scaleFactor = 1; %amount to scale the input by.
  end
  
  methods
    function obj = RigidBodyThrust(parent_body, xyz, rpy, axis, scaleFac, limits)
      if ~isa(parent_body, 'numeric');
        error('Drake:RigidBodyThrust:InvalidParent','Force Type Thrust does not have a proper RigidBody parent');
      end
      
      obj.axis = axis/norm(axis);      
      obj.kinframe = RigidBodyFrame(parent_body,xyz,rpy);
      
      obj.direct_feedthrough_flag = true;
      obj.input_num = 0;
      obj.input_limits = [-inf inf];
      if (nargin > 3)
        obj.scaleFactor = scaleFac;
      end
      if (nargin > 4)
        obj.input_limits = limits;
      end
    end %constructor
    
    function [force, B_mod] = computeSpatialForce(obj,manip,q,qd)
      %B_mod maps the input to generalized forces.
      kinsol = doKinematics(manip,q);
      
      [x,J] = forwardKin(obj.kinframe,manip,kinsol,zeros(3,1));
      B_mod = manip.B*0; %initialize B_mod
      
      axis_world = forwardKin(obj.kinframe,manip,kinsol,obj.axis);
      axis_world = axis_world-x;
      
      force = sparse(6,getNumBodies(manip));
      
      % apply force along the z-axis of the reference frame
      B_mod(:,obj.input_num) = obj.scaleFactor*J'*axis_world;
    end
    
    function obj = updateBodyIndices(obj,map_from_old_to_new)
      obj.kinframe = updateBodyIndices(obj.kinframe,map_from_old_to_new);
    end
    
    function obj = updateForRemovedLink(obj,model,body_ind)
      obj.kinframe = updateForRemovedLink(obj.kinframe,model,body_ind);
    end
    
  end
  
  methods (Static)
    function obj = parseURDFNode(model,robotnum,node,options)
      elnode = node.getElementsByTagName('parent').item(0);
      parent = findLinkInd(model,char(elnode.getAttribute('link')),robotnum);
      
      xyz = zeros(3,1); rpy = zeros(3,1);
      if elnode.hasAttribute('xyz')
        xyz = reshape(parseParamString(model,robotnum,char(elnode.getAttribute('xyz'))),3,1);
      end
      if elnode.hasAttribute('rpy')
        rpy = reshape(parseParamString(model,robotnum,char(elnode.getAttribute('rpy'))),3,1);
      end
      
      axis = [1; 0; 0];
      elnode = node.getElementsByTagName('axis').item(0);
      if ~isempty(elnode)
        axis = reshape(parseParamString(model,robotnum,char(elnode.getAttribute('xyz'))),3,1);
      end
      
      scaleFac = 1;
      if node.hasAttribute('scale_factor')
        scaleFac = parseParamString(model,robotnum,char(node.getAttribute('scale_factor')));
      end
      
      limits = [-inf,inf];
      if node.hasAttribute('lower_limit')
        limits(1) = parseParamString(model,robotnum,char(node.getAttribute('lower_limit')));
      end
      if node.hasAttribute('upper_limit')
        limits(2) = parseParamString(model,robotnum,char(node.getAttribute('upper_limit')));
      end
      
      obj = RigidBodyThrust(parent, xyz, rpy, axis, scaleFac, limits);
    end
  end
  
end
