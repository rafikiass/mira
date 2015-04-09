# Add the DraftVersion module for all types of objects that
# need to have draft vs. published versions of the object.

models = [TuftsAudio, TuftsEAD, TuftsGenericObject, TuftsImage,
          TuftsPdf, TuftsRCR, TuftsTEI, TuftsVotingRecord]

models.each do |model|
  model.include DraftVersion
end

