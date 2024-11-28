db.getCollection('loyalty_transactions').find({ type: 'adjust qual' }).count();
db.getCollection('loyalty_transactions').deleteMany({ type: 'adjust qual' });

db.getCollection('loyalty_members').updateMany({}, [
  {
    $set: {
      total_spending: {
        $convert: {
          input: '$total_spending',
          to: 'int'
        }
      },
      qualification_points: {
        $convert: {
          input: '$qualification_points',
          to: 'int'
        }
      }
    }
  }
]);

db.getCollection('loyalty_members').updateMany({}, [
  {
    $set: {
      total_spending: Int32(0),
      qualification_points: Int32(0)
    }
  }
]);

db.getCollection('loyalty_members').updateMany({}, [
  {
    $set: {
      tier: '4272b1ff-e786-4fe7-8186-eb6335857084',
      old_tier: null
    }
  }
]);

db.collezioneA.aggregate([
  {
    $lookup: {
      from: 'collezioneB', // La collezione da unire
      localField: 'campo1', // Il campo nella collezioneA
      foreignField: 'campo2', // Il campo nella collezioneB
      as: 'matching_docs' // Il nome del nuovo array risultante
    }
  },
  {
    $match: {
      matching_docs: { $size: 0 } // Filtra i documenti dove "matching_docs" è un array vuoto
    }
  }
]);
