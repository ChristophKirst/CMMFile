% determine c++ dimension vector
% appropiate for write out as in cmmfile.h 
% e.g. via cmm_write_header(f, t, s)

function s = cmm_dim(data)
   if isscalar(data) || ischar(data)
      s = [];
      return
   end
   
   s = size(data);
   l = length(s);
   if s(1)==1 && l==2 
      s = s(2);
      return
   end
   if l > 2
      ss = s(2); s(2) = s(1); s(1) = ss;
      s = s(end:-1:1);
   end
end