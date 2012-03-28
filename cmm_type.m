%cmm_type or data as used by cmmfile.h 
function type = cmm_type(data)
   if iscell(data)
      if ischarcell(data)
         type = 'T';
      else
         type = cell(1, length(data));
         for k=1:length(data)
            type(k) = cmm_type(data{k});
         end
      end
      return
   else
      type = to_cmm_type(class(data));
   end
end