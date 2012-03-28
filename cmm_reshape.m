% reshapes data given as flat list and s cmm_dim vector 
% as written by cmmfile.h to corresponding matlab array
% s = [] indicates scalar
function r = cmm_reshape(data, s)
   l = length(s);
   switch l
      case 0
         r = data;
      case 1
         if s<0
            s = numel(data);
         end
         r = reshape(data, [1 s]);
      otherwise
         if s(1)<0
            s(1)=numel(data)/prod(s(2:end));
         end
         r = reshape(data, s(end:-1:1));
         per = 1:l; 
         per(1) = 2; per(2) = 1;
         r = permute(r, per);
   end
end