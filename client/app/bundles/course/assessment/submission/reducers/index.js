import { combineReducers } from 'redux';
import form from './form';
import annotations from './annotations';
import assessment from './assessment';
import attachments from './attachments';
import commentForms from './commentForms';
import explanations from './explanations';
import notification from './notification';
import posts from './posts';
import questions from './questions';
import questionsFlags from './questionsFlags';
import submission from './submission';
import submissionFlags from './submissionFlags';
import submissions from './submissions';
import scribing from './scribing';
import topics from './topics';
import grading from './grading';
import testCases from './testCases';

export default combineReducers({
  annotations,
  attachments,
  assessment,
  commentForms,
  explanations,
  notification,
  posts,
  questions,
  questionsFlags,
  submission,
  submissionFlags,
  submissions,
  scribing,
  topics,
  grading,
  testCases,
  form,
});
